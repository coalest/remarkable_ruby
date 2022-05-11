module RemarkableRuby
  class Item
    attr_reader :uuid, :path, :message, :success, :blob_url_get, :bookmarked, 
      :blob_url_get_expires, :modified_client, :type, :current_page,
      :connection

    attr_accessor :parent, :name, :version

    def initialize(attrs: nil, client: nil)
      @client = client ? client : Client.new
      @connection = @client.connection

      attrs.nil? ? init_from_defaults : init_from_attributes(attrs)
    end

    # Delete a document from device and cloud
    def delete!
      payload = [{ ID: uuid, Version: version }]
      response = connection.put("/document-storage/json/2/delete", payload)
    end

    # Move a document to the trash folder
    def delete
      update(parent: "trash")
    end

    def upload
      url = put_blob_url
      upload_file(url)
      update_metadata(attributes)
    end

    def update(name: nil, parent: nil, bookmarked: nil)
      return unless name || parent || bookmarked

      self.name = name if name
      self.parent = parent if parent
      self.bookmarked = bookmarked if bookmarked
      self.version += 1
      update_metadata(attributes)
    end

    # Download the zip file for a given document in the user's current directory
    def download
      file_name = "#{uuid}.zip"
      return if File.exists?(file_name)

      dl_link = get_blob_url

      streamed = []
      @connection.get(dl_link) do |req|
        req.options.on_data = Proc.new { |chunk| streamed << chunk }
      end
      File.write(file_name, streamed.join)

      file_name
    end

    private

    def update_metadata(attrs)
      payload = [attrs].to_json
      @connection.put("document-storage/json/2/upload/update-status", payload)
    end

    def upload_file(url)
      # Create the zip in a temp dir
      zip_doc = ZipDocument.new(self).dump

      # Send zip with put http request
      file_data = File.read(zip_doc)
      connection = @client.upload_connection(url)
      response = connection.put("", file_data)

      # Delete zip from temp dir
      FileUtils.remove_entry(zip_doc)
    end


    def get_blob_url
      params = { doc: uuid, withBlob: true }
      response = @connection.get("document-storage/json/2/docs", params)
      JSON.parse(response.body).first['BlobURLGet']
    end

    def put_blob_url
      payload = [{ "ID": uuid, "Type": type, "Version": version }]
      response = @connection.put("document-storage/json/2/upload/request", payload)
      JSON.parse(response.body).first["BlobURLPut"]
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
