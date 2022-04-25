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
      return if tokens.nil?

      @device_token = tokens['devicetoken']
      @user_token = refresh_token
    end

    def register_device(one_time_code)
      body = { deviceDesc: "desktop-macos",
                  code: one_time_code,
                  deviceID: SecureRandom.uuid }.to_json
      response = auth_connection.post(DEVICE_TOKEN_ENDPOINT, body, {})
      device_token = handle_response(response).body

      @device_token = device_token
      @user_token = refresh_token
      Config.save(device_token: @device_token, user_token: @user_token)
    end

    # returns metadata for all files by default, unless a doc uuid is given
    def get_docs(download_links: false)
      params = download_links ? { 'withBlob': true } : {}
      response = connection.get("document-storage/json/2/docs", params)
      Collection.from_response(response)
    end

    def get_doc(uuid:, download_link: false)
      params = download_link ? { 'withBlob': true } : {}
      params[:doc] = uuid
      response = connection.get("document-storage/json/2/docs", params)
      hash = JSON.parse(response.body).first
      Document.new(hash)
    end

    # Download the zip file for a given document in the user's current directory
    def download_doc(uuid)
      params = { doc: uuid, withBlob: true }
      response = connection.get("document-storage/json/2/docs", params)

      dl_link = extract_link(response)
      streamed = []
      connection.get(dl_link) do |req|
        req.options.on_data = Proc.new { |chunk| streamed << chunk }
      end
      new_file_name = "#{uuid}.zip"
      File.write(new_file_name, streamed.join)
      new_file_name
    end
    
    def create_folder(name:, location: "")
      payload = { name: name, location: location }.merge(Folder.defaults)
      response = connection.put("document-storage/json/2/upload/update-status", payload)
      handle_response(response)
    end

    def delete_doc(uuid:)
      version = get_doc(uuid: uuid).Version
      payload = [{ ID: uuid, Version: version }]
      response = connection.put("/document-storage/json/2/delete", payload)
    end

    def is_auth?
      !!@user_token
    end

    def connection
      @connection ||= Faraday.new(storage_url) do |conn|
        conn.request :authorization, :Bearer, @user_token
        conn.request :json
        conn.response :json, content_type: "application/json"
      end
    end

    private

    def auth_connection
      Faraday.new(APP_URL) do |conn|
        conn.request :authorization, :Bearer, @device_token
        conn.request :json
        conn.response :json, content_type: "application/json"
      end
    end

    def storage_url
      return @storage_url if @storage_url

      conn = Faraday.new(url: SERVICE_DISCOVERY_URL)     
      response = conn.get(SERVICE_DISCOVERY_ENDPOINT)
      body = JSON.parse(response.body)
      @storage_url = "https://" + body["Host"]
    end

    def refresh_token
      response = auth_connection.post(USER_TOKEN_ENDPOINT)
      response.body
    end

    def extract_link(response)
      JSON.parse(response.body)[0]['BlobURLGet']
    end

    def handle_response(response)
      status = response.status
      return response if response.status == 200

      raise Error, "HTTP Status Code #{status}: #{response.body}"
    end
  end
end
