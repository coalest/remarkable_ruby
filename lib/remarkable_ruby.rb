# frozen_string_literal: true

require_relative "remarkable_ruby/version"
require_relative "remarkable_ruby/config"
require "faraday"
require "faraday/net_http"
require "securerandom"
require "json"

Faraday.default_adapter = :net_http

module ReMarkableRuby
  class Error < StandardError; end

  class Client
    APP_URL = "https://webapp-production-dot-remarkable-production.appspot.com/"
    SERVICE_DISCOVERY_URL = "https://service-manager-production-dot-remarkable-production.appspot.com/"

    def initialize(one_time_code = nil)
      tokens = Config.load_tokens || {}
      
      @device_token = tokens['devicetoken'] || authenticate(one_time_code)
      @user_token = tokens['usertoken'] || refresh_token
      Config.save(device_token: @device_token, user_token: @user_token)

      @storage_uri = fetch_storage_uri
    end

    def files
      conn = Faraday.new(
        url: "https://#{@storage_uri}?withBlob=true/",
        headers: {'Authorization' => "Bearer #{@user_token}"}
      )
      response = conn.get("document-storage/json/2/docs")
      JSON.parse(response.body)
    end

    private

    def authenticate(one_time_code)
      conn = Faraday.new(
        url: APP_URL,
        headers: {'Authorization' => "Bearer "}
      )
      payload = { deviceDesc: "desktop-macos",
                  code: one_time_code,
                  deviceID: SecureRandom.uuid }.to_json
      response = conn.post("token/json/2/device/new", payload,
                           "Content-Type" => "application/json")
      response.body
    end

    def fetch_storage_uri
      conn = Faraday.new(url: SERVICE_DISCOVERY_URL,
                         headers: {'Authorization: Bearer' => "#{@device_token}"})     
      response = conn.get('service/json/1/document-storage?environment=production&group=auth0%7C5a68dc51cb30df3877a1d7c4&apiVer=2')
      response_body = JSON.parse(response.body)
      response_body["Host"]
    end

    def refresh_token
      conn = Faraday.new(url: APP_URL,
                         headers: {'Authorization' => "Bearer #{@device_token}"})
      response = conn.post("token/json/2/user/new", "", "Content-Type" => "application/json")
      response.body
    end
  end
end

