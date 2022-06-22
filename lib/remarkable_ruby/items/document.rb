module RemarkableRuby
  class Document < Item
    def initialize(attrs: nil, client: nil, path: nil)
      @type = "DocumentType"
      super
    end

    # Download the zip file for a given document in the user's current directory
    def download
      file_name = "#{uuid}.zip"
      return if File.exist?(file_name)

      dl_link = get_blob_url

      streamed = []
      @connection.get(dl_link) do |req|
        req.options.on_data = proc { |chunk| streamed << chunk }
      end
      File.write(file_name, streamed.join)

      file_name
    end

    # Move a document to the trash folder
    def delete
      update(parent: "trash")
    end

    # Delete a document from device and cloud
    def delete!
      payload = [{ID: uuid, Version: version}]
      connection.put("/document-storage/json/2/delete", payload)
    end

    # Return an array of highlights from a document
    def highlights
      highlights = []
      download unless File.exist?("#{uuid}.zip")
      Zip::File.open("#{uuid}.zip") do |zip_doc|
        zip_doc.select { |file| file.name.include?("highlights") }.each do |file|
          json = JSON.parse(file.get_input_stream.read)["highlights"].first
          page_highlights = json.map { |attrs| Highlight.new(attrs) }
          highlights << Highlight.join_adjacent(page_highlights)
        end
      end
      highlights.flatten
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

    private

    def upload_file(url)
      # Create the zip in a temp dir
      zip_doc = ZipDocument.new(self).dump

      # Send zip with put http request
      file_data = File.read(zip_doc)
      connection = @client.upload_connection(url)
      connection.put("", file_data)

      # Delete zip from temp dir
      FileUtils.remove_entry(zip_doc)
    end

    def update_metadata(attrs)
      payload = [attrs].to_json
      @connection.put("document-storage/json/2/upload/update-status", payload)
    end

    def get_blob_url
      params = {doc: uuid, withBlob: true}
      response = @connection.get("document-storage/json/2/docs", params)
      JSON.parse(response.body).first["BlobURLGet"]
    end

    def put_blob_url
      payload = [{ID: uuid, Type: type, Version: version}]
      response = @connection.put("document-storage/json/2/upload/request", payload)
      JSON.parse(response.body).first["BlobURLPut"]
    end
  end
end
