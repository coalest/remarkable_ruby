# frozen_string_literal: true

require_relative "reMarkableRuby/version"
require "faraday"
require "faraday/net_http"
require "securerandom"
require "json"

module ReMarkableRuby
  class Error < StandardError; end

  class Client
    attr_reader :auth_token

    def initialize(one_time_code)
      @conn = establish_connection
      @auth_token = authenticate(one_time_code)
    end

    def establish_connection
      Faraday.default_adapter = :net_http
      Faraday.new(url: 'https://webapp-production-dot-remarkable-production.appspot.com/',
                  headers: {'Authorization: Bearer' => ''})     
    end

    def authenticate(one_time_code)
      payload = { deviceDesc: "desktop-macos",
                  code: one_time_code,
                  deviceID: SecureRandom.uuid }.to_json
      response = @conn.post("token/json/2/device/new", payload,
                            "Content-Type" => "application/json")
      response.body
    end
  end
end


