module RemarkableRuby
  class Item
    attr_reader :uuid, :path, :message, :success, :blob_url_get, :bookmarked, 
      :blob_url_get_expires, :modified_client, :type, :current_page,
      :connection

    attr_accessor :parent, :name, :version

    def initialize(attrs: nil, client: nil, path: nil)
      @client = client ? client : Client.new
      @connection = @client.connection
      @path = path
      @name = File.basename(path) if path

      attrs.nil? ? init_from_defaults : init_from_attributes(attrs)
    end

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

    def attributes
      { "ID": @uuid,
        "BlobURLGet": @blob_url_get,
        "CurrentPage": @current_page,
        "BlobURLGetExpires": @blob_url_get_expires,
        "Message": @message,
        "Success": @success,
        "Bookmarked": @bookmarked,             
        "Version": @version, 
        "ModifiedClient": @modified_client,
        "Type": @type,
        "VissibleName": @name,
        "Parent": @parent }
    end
  end
end
