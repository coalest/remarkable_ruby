# frozen_string_literal: true

require_relative "remarkable_ruby/version"
require_relative "remarkable_ruby/config"
require "faraday"
require "faraday/net_http"
require "securerandom"
require "json"

Faraday.default_adapter = :net_http

module RemarkableRuby
  class Error < StandardError; end

  class Client
    APP_URL = "https://webapp-production-dot-remarkable-production.appspot.com/"
    SERVICE_DISCOVERY_URL = "https://service-manager-production-dot-remarkable-production.appspot.com/"

    def initialize(one_time_code = nil)
      tokens = Config.load_tokens || {}
      
      @device_token = tokens['devicetoken'] || authenticate(one_time_code)
      @user_token = refresh_token
      Config.save(device_token: @device_token, user_token: @user_token)

      @storage_uri = fetch_storage_uri
    end

    # returns metadata for all files by default, unless a doc uuid is given
    def get_metadata(doc_uuid: nil, with_dl_links: false)
      conn = Faraday.new(url: @storage_uri, headers: auth_header(@user_token))
      response = conn.get("document-storage/json/2/docs") do |req|
        req.params['doc'] = doc_uuid if doc_uuid
        req.params['withBlob'] = with_dl_links if with_dl_links
      end

      JSON.parse(response.body)
    end

    private

    def authenticate(one_time_code)
      conn = Faraday.new(url: APP_URL, headers: auth_header)
      payload = { deviceDesc: "desktop-macos",
                  code: one_time_code,
                  deviceID: SecureRandom.uuid }.to_json
      response = conn.post("token/json/2/device/new", payload,
                           "Content-Type" => "application/json")
      response.body
    end

    def fetch_storage_uri
      conn = Faraday.new(url: SERVICE_DISCOVERY_URL, headers: auth_header(@user_token))     
      response = conn.get('service/json/1/document-storage?environment=production&group=auth0%7C5a68dc51cb30df3877a1d7c4&apiVer=2')
      response_body = JSON.parse(response.body)
      "https://" + response_body["Host"]
    end

    def refresh_token
      conn = Faraday.new(url: APP_URL, headers: auth_header(@device_token))
      response = conn.post("token/json/2/user/new", "", "Content-Type" => "application/json")
      response.body
    end

    def auth_header(token = nil)
      {'Authorization' => "Bearer #{token}"}
    end
  end
end

