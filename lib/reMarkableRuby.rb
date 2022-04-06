# frozen_string_literal: true

require_relative "reMarkableRuby/version"
require "faraday"
require "faraday/net_http"
require "securerandom"
require "json"

module ReMarkableRuby
  class Error < StandardError; end

  class Client
    APP_URL = "https://webapp-production-dot-remarkable-production.appspot.com/"

    def initialize(one_time_code)
      Faraday.default_adapter = :net_http

      @uuid = SecureRandom.uuid
      @auth_token = authenticate(one_time_code)
      @storage_uri = fetch_storage_uri
      refresh_token(@auth_token)
    end

    def files
      conn = Faraday.new(
        url: "https://#{@storage_uri}?withBlob=true/",
        headers: {'Authorization' => "Bearer #{auth_token}"}
      )
      response = conn.get("document-storage/json/2/docs")
      JSON.parse(response.body)
    end


    def refresh_token(auth_token)
      conn = Faraday.new(url: APP_URL,
                         headers: {'Authorization' => "Bearer #{auth_token}"})
      response = conn.post("token/json/2/user/new", "", "Content-Type" => "application/json")

      @auth_token = response.body
    end

    private
    attr_reader :auth_token

    def authenticate(one_time_code)
      conn = Faraday.new(
        url: APP_URL,
        headers: {'Authorization' => "Bearer "}
      )
      payload = { deviceDesc: "desktop-macos",
                  code: one_time_code,
                  deviceID: @uuid }.to_json
      response = conn.post("token/json/2/device/new", payload,
                           "Content-Type" => "application/json")
      response.body
    end

    def fetch_storage_uri
      conn = Faraday.new(url: 'https://service-manager-production-dot-remarkable-production.appspot.com/',
                         headers: {'Authorization: Bearer' => "#{auth_token}"})     
      response = conn.get('service/json/1/document-storage?environment=production&group=auth0%7C5a68dc51cb30df3877a1d7c4&apiVer=2')
      response_body = JSON.parse(response.body)
      response_body["Host"]
    end
  end
end

