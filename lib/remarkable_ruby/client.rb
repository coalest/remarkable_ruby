module RemarkableRuby
  class Client
    APP_URL = "https://webapp-production-dot-remarkable-production.appspot.com/"
    SERVICE_DISCOVERY_URL = "https://service-manager-production-dot-remarkable-production.appspot.com/"
    DEVICE_TOKEN_ENDPOINT = "token/json/2/device/new"
    USER_TOKEN_ENDPOINT = "token/json/2/user/new"
    SERVICE_DISCOVERY_ENDPOINT = "service/json/1/document-storage?"\
      "environment=production&group=auth0%7C5a68dc51cb30df3877a1d7c4&apiVer=2"

    def initialize
      tokens = Config.load_tokens
      if tokens
        @device_token = tokens['devicetoken']
        @user_token = refresh_token
        @storage_uri = fetch_storage_uri
      end
    end

    def register_device(one_time_code)
      conn = Faraday.new(url: APP_URL, headers: auth_header)
      payload = { deviceDesc: "desktop-macos",
                  code: one_time_code,
                  deviceID: SecureRandom.uuid }.to_json
      response = conn.post(DEVICE_TOKEN_ENDPOINT, payload,
                           "Content-Type" => "application/json")

      if response.body.downcase.include?("invalid")
        raise Error.new("Invalid one-time code")
      end

      @device_token = response.body
      @user_token = refresh_token
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
      new_file_name = "#{uuid}.zip"
      File.write(new_file_name, streamed.join)
      new_file_name
    end

    def is_auth?
      @user_token.nil?
    end

    private

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
        raise Error.new("Invalid device token")
      end

      response.body
    end

    def auth_header(token = nil)
      {'Authorization' => "Bearer #{token}"}
    end
  end
end
