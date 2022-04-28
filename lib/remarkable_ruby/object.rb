module RemarkableRuby
  class Object
    attr_reader :uuid, :version, :message, :success, :blob_url_get,
      :blob_url_get_expires, :modified_client, :type, :name, :current_page,
      :bookmarked, :parent, :connection

    def initialize(attrs, connection)
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
      @connection = connection
    end

    def inspect
      "#<#{self.class}:#{self.object_id} " + 
      "@name='#{@name}', " +
      "@uuid='#{@uuid}>"
    end
  end
end
