# frozen_string_literal: true

require_relative "remarkable_ruby/version"
require_relative "remarkable_ruby/config"
require_relative "remarkable_ruby/error"
require "faraday"
require "faraday/net_http"
require "securerandom"
require "json"
require "zip"

Faraday.default_adapter = :net_http

module RemarkableRuby
  class Client
    APP_URL = "https://webapp-production-dot-remarkable-production.appspot.com/"
    SERVICE_DISCOVERY_URL = "https://service-manager-production-dot-remarkable-production.appspot.com/"
    DEVICE_TOKEN_ENDPOINT = "token/json/2/device/new"
    USER_TOKEN_ENDPOINT = "token/json/2/user/new"

    def initialize(one_time_code = nil)
      tokens = Config.load_tokens || {}
      @device_token = tokens['devicetoken'] || authenticate(one_time_code)
      @user_token = refresh_token
      @storage_uri = fetch_storage_uri

      Config.save(device_token: @device_token, user_token: @user_token)
    end

    # returns metadata for all files by default, unless a doc uuid is given
    def get_metadata(uuid: nil, with_dl_links: false)
      conn = Faraday.new(url: @storage_uri, headers: auth_header(@user_token))
      response = conn.get("document-storage/json/2/docs") do |req|
        req.params['doc'] = uuid if uuid
        req.params['withBlob'] = with_dl_links if with_dl_links
      end

      JSON.parse(response.body)
    end

    # Download the zip file for a given document in the user's current directory
    def download_doc(uuid = '')
      conn = Faraday.new(url: @storage_uri, headers: auth_header(@user_token))
      response = conn.get("document-storage/json/2/docs") do |req|
        req.params['doc'] = uuid
        req.params['withBlob'] = true
      end
      dl_link = JSON.parse(response.body)[0]['BlobURLGet']
      streamed = []
      conn.get(dl_link) do |req|
        req.options.on_data = Proc.new { |chunk| streamed << chunk }
      end
      File.write("#{uuid}.zip", streamed.join)
    end

    # returns array of highlight hashes
    # TODO: clean up highlights (remove duplicates and join touching)
    # TODO: make highlight class
    def extract_highlight_doc(uuid)
      path_to_zip = "#{Dir.getwd}/#{uuid}.zip"
      download_doc(uuid) unless File.exists?(path_to_zip)

      highlights = []
      Zip::File.open(path_to_zip) do |zip|
        zip.each do |file|
          next unless highlight_file?(file.name)
          
          some_highlights = JSON.parse(file.get_input_stream.read)['highlights'][0]
          highlights << some_highlights
        end
      end
      highlights.flatten
    end

    private

    def authenticate(one_time_code)
      unless valid?(one_time_code)
        raise AuthError.new("One-time code should be 8 letters long")
      end

      conn = Faraday.new(url: APP_URL, headers: auth_header)
      payload = { deviceDesc: "desktop-macos",
                  code: one_time_code,
                  deviceID: SecureRandom.uuid }.to_json
      response = conn.post(DEVICE_TOKEN_ENDPOINT, payload,
                           "Content-Type" => "application/json")

      if response.body.downcase.include?("invalid")
        raise AuthError.new("Invalid one-time code")
      else
        response.body
      end
    end

    def fetch_storage_uri
      conn = Faraday.new(url: SERVICE_DISCOVERY_URL)     
      response = conn.get('service/json/1/document-storage?environment=production&group=auth0%7C5a68dc51cb30df3877a1d7c4&apiVer=2')
      response_body = JSON.parse(response.body)
      "https://" + response_body["Host"]
    end

    def refresh_token
      conn = Faraday.new(url: APP_URL, headers: auth_header(@device_token))
      response = conn.post(USER_TOKEN_ENDPOINT, "", "Content-Type" => "application/json")

      if response.body.downcase.include?("invalid")
        raise AuthError.new("Invalid device token")
      end

      response.body
    end

    def auth_header(token = nil)
      {'Authorization' => "Bearer #{token}"}
    end

    def valid?(one_time_code)
      one_time_code.is_a? String && one_time_code.length == 8
    end

    def highlight_file?(file_path)
      file_name = file_path.split("/").last
      file_name.split('.').last == "json" && file_name.length == 41
    end
  end
end
