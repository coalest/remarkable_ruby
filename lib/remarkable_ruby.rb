# frozen_string_literal: true

require "faraday"
require "faraday/net_http"
require "securerandom"
require "json"
require "zip"
require "yaml"
require "pry"

module RemarkableRuby
  autoload :Client, "remarkable_ruby/client"
  autoload :Version, "remarkable_ruby/version"
  autoload :Config, "remarkable_ruby/config"
  autoload :Error, "remarkable_ruby/error"
  autoload :Highlight, "remarkable_ruby/highlight"
  autoload :Object, "remarkable_ruby/object"
  autoload :ZipDocument, "remarkable_ruby/zip_document"

  autoload :Folder, "remarkable_ruby/objects/folder"
  autoload :Document, "remarkable_ruby/objects/document"
end
