module RemarkableRuby
  class Object
    attr_reader :uuid, :version, :message, :success, :blob_url_get,
      :blob_url_get_expires, :modified_client, :type, :name, :current_page,
      :bookmarked, :parent, :connection, :path, :name

    def initialize(attrs: nil, connection: nil, path: nil)
      if path
        @path = path
        @name = File.basename(path)
        set_defaults
      else
        @uuid = attrs["ID"] 
        @version = attrs["Version"]
        @message = attrs["Message"]
        @success = attrs["Success"]
        @blob_url_get = attrs["BloblURLGet"]
        @blob_url_get_expires = attrs["BlobURLGetExpires"]
        @modified_client = attrs["ModifiedClient"]
        @type = attrs["Type"]
        @name = attrs["VissibleName"]
        @current_page = attrs["CurrentPage"]
        @bookmarked = attrs["Bookmarked"]
        @parent = attrs["Parent"]
      end

      @connection = connection ? connection : Client.new.connection
    end

#     def inspect
#       "#<#{self.class}:#{self.object_id} " + 
#       "@name='#{@name}', " +
#       "@uuid='#{@uuid}>"
#     end

    def set_defaults
      @uuid = SecureRandom.uuid
      @version = 1
      @type = "DocumentType"
      @message = ""
      @success = true
      @blob_url_get = ""
      @blob_url_get_expires = "0001-01-01T00:00:00Z"
      @modified_client = Time.now.strftime("%Y-%m-%dT%H:%M:%SZ")
      @current_page = 0
      @bookmarked = false
      @parent = ""
    end
  end
end
