module RemarkableRuby
  class Object
    attr_reader :uuid, :version, :message, :success, :blob_url_get,
      :blob_url_get_expires, :modified_client, :type, :name, :current_page,
      :bookmarked, :parent, :connection, :path, :name

    def initialize(attrs: nil, connection: nil, path: nil)
      @connection = connection ? connection : Client.new.connection
      @path = path
      @name = File.basename(path) if path

      attrs.nil? ? init_from_defaults : init_from_attributes(attrs)
    end

#     def inspect
#       "#<#{self.class}:#{self.object_id} " + 
#       "@name='#{@name}', " +
#       "@uuid='#{@uuid}>"
#     end

    def init_from_defaults
      @uuid = SecureRandom.uuid
      @version = 1
      @message = ""
      @success = true
      @blob_url_get = ""
      @blob_url_get_expires = "0001-01-01T00:00:00Z"
      @modified_client = Time.now.strftime("%Y-%m-%dT%H:%M:%SZ")
      @current_page = 0
      @bookmarked = false
      @parent = ""
    end

    def init_from_attributes(attrs)
      @uuid = attrs["ID"] 
      @version = attrs["Version"]
      @message = attrs["Message"]
      @success = attrs["Success"]
      @blob_url_get = attrs["BloblURLGet"]
      @blob_url_get_expires = attrs["BlobURLGetExpires"]
      @modified_client = attrs["ModifiedClient"]
      @name = attrs["VissibleName"]
      @current_page = attrs["CurrentPage"]
      @bookmarked = attrs["Bookmarked"]
      @parent = attrs["Parent"]
    end
  end
end
