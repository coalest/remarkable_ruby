module RemarkableRuby
  class Document < Item
    def initialize(attrs: nil, client: nil, path: nil)
      @type = "DocumentType"
      super
    end

    # Download the zip file for a given document in the user's current directory
    def download
      file_name = "#{uuid}.zip"
      return if File.exists?(file_name)

      url = blob_url_get
      download_zip(url, file_name)
    end

    # Move a document to the trash folder
    def delete
      update(parent: "trash")
    end

    # Delete a document from device and cloud
    def delete!
      payload = [{ ID: uuid, Version: version }]
      put_request("/document-storage/json/2/delete", body: payload)
    end

    # Return an array of highlights from a document
    def highlights
      highlights = []
      download unless File.exists?("#{uuid}.zip")
      Zip::File.open("#{uuid}.zip") do |zip_doc|
        zip_doc.select { |file| file.name.include?("highlights") }.each do |file|
          json = JSON.parse(file.get_input_stream.read)['highlights'].first
          page_highlights = json.map{ |attrs| Highlight.new(attrs) }
          highlights << Highlight.join_adjacent(page_highlights)
        end
      end
      highlights.flatten
    end

    def upload
      url = blob_url_put
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
      put_request_to_storage(url, body: file_data)

      # Delete zip from temp dir
      FileUtils.remove_entry(zip_doc)
    end

    def update_metadata(attrs)
      payload = [attrs].to_json
      put_request("document-storage/json/2/upload/update-status", body:payload)
    end

    def get_request(url, params: {}, headers: {})
      handle_response @client.connection.get(url, params, headers)
    end

    def put_request(url, body: {}, headers: {})
      handle_response @client.connection.put(url, body, headers)
    end

    def put_request_to_storage(url, body: {}, headers: {})
      connection = @client.upload_connection(url)
      handle_response connection.put("", body, headers)
    end
    
    def blob_url_get
      params = { doc: uuid, withBlob: true }
      response = get_request("document-storage/json/2/docs", params: params)
      JSON.parse(response.body).first['BlobURLGet']
    end

    def blob_url_put
      payload = [{ "ID": uuid, "Type": type, "Version": version }]
      response = put_request("document-storage/json/2/upload/request", body: payload)
      JSON.parse(response.body).first["BlobURLPut"]
    end

    def download_zip(url, file_name)
      streamed = []
      response = @client.connection.get(url) do |req|
        req.options.on_data = Proc.new { |chunk| streamed << chunk }
      end
      handle_response(response)
      File.write(file_name, streamed.join)

      file_name
    end
  end
end
