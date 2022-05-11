# frozen_string_literal: true

require "faraday"
require "faraday/net_http"
require "securerandom"
require "json"
require "zip"
require "yaml"

module RemarkableRuby
  autoload :Client, "remarkable_ruby/client"
  autoload :Version, "remarkable_ruby/version"
  autoload :Config, "remarkable_ruby/config"
  autoload :Error, "remarkable_ruby/error"
  autoload :Highlight, "remarkable_ruby/highlight"
  autoload :Item, "remarkable_ruby/item"
  autoload :ZipItem, "remarkable_ruby/zip_item"

  autoload :Folder, "remarkable_ruby/items/folder"
  autoload :Document, "remarkable_ruby/items/document"
end
