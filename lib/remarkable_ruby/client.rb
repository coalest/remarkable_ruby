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

      @device_token = tokens["devicetoken"]
      @user_token = refresh_user_token
    end

    # returns metadata for all files
    def documents(download_links: false)
      params = download_links ? {withBlob: true} : {}
      response = connection.get("document-storage/json/2/docs", params)
      create_new_items(response)
    end

    # returns metadata for one file
    def document(uuid:, download_link: false)
      params = download_link ? {withBlob: true} : {}
      params[:doc] = uuid
      response = connection.get("document-storage/json/2/docs", params)
      attrs = JSON.parse(response.body).first
      Document.new(attrs: attrs)
    end

    def register_device(one_time_code)
      response = auth_connection.post(DEVICE_TOKEN_ENDPOINT, new_device_body(one_time_code), {})
      device_token = handle_response(response).body

      @device_token = device_token
      @user_token = refresh_user_token
      Config.save(device_token: @device_token, user_token: @user_token)
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

    def upload_connection(url)
      Faraday.new(url) do |conn|
        conn.request :authorization, :Bearer, @user_token
        conn.headers["Content-Type"] = ""
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

    def refresh_user_token
      response = auth_connection.post(USER_TOKEN_ENDPOINT)
      response.body
    end

    def handle_response(response)
      status = response.status
      message = response.body
      return response if response.status == 200

      raise Error, "HTTP Status Code #{status}: #{message}"
    end

    def create_new_items(response)
      body = JSON.parse(response.body)
      body.map do |attrs|
        case attrs["Type"]
        when "CollectionType" then Folder.new(attrs: attrs, client: self)
        when "DocumentType" then Document.new(attrs: attrs, client: self)
        end
      end
    end

    def new_device_body(one_time_code)
      {deviceDesc: "desktop-macos",
       code: one_time_code,
       deviceID: SecureRandom.uuid}.to_json
    end
  end
end
