# frozen_string_literal: true

require "faraday"
require "faraday/net_http"
require "securerandom"
require "json"
require "zip"

module RemarkableRuby
  autoload :Client, "remarkable_ruby/client"
  autoload :Version, "remarkable_ruby/version"
  autoload :Config, "remarkable_ruby/config"
  autoload :Error, "remarkable_ruby/error"
end
