module RemarkableRuby
  class Document < Object
    def initialize(attrs: nil, connection: nil, path: nil)
      @type = "DocumentType"
      super
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

    # Delete a document from 
    def delete
      payload = [{ ID: uuid, Version: version }]
      response = connection.put("/document-storage/json/2/delete", payload)
    end

    # Return an array of highlights from a document
    def highlights
      highlights = []
      download unless File.exists?("#{uuid}.zip")
      Zip::File.open("#{uuid}.zip") do |zip_file|
        zip_file.each do |entry|
          next unless entry.name.include?("highlights")

          json = JSON.parse(entry.get_input_stream.read)['highlights'].first
          page_highlights = json.map{ |attrs| Highlight.new(attrs) }
          highlights << Highlight.join_adjacent(page_highlights)
        end
      end
      highlights.flatten
    end

    def upload
      # Get URL for put request
      payload = [{ "ID": uuid, "Type": type, "Version": version }]
      response = @connection.put("document-storage/json/2/upload/request", payload)
      put_url = JSON.parse(response.body).first["BlobURLPut"]

      # Create and send zip to URL
      zip_doc = ZipDocument.new(self).dump
      user_token = Config.load_tokens['usertoken']
      file_data = File.read(zip_doc)
      connection = Faraday.new(put_url) do |conn|
          conn.request :authorization, :Bearer, user_token
          conn.headers['Content-Type'] = ""
      end
      response = connection.put("", file_data) do |r|
      end
      FileUtils.remove_entry(zip_doc)

      # Update metadata so that pdf is visible on device
      payload = attributes_json
      response = @connection.put("document-storage/json/2/upload/update-status", payload)
    end

    private

    def get_blob_url
      params = { doc: uuid, withBlob: true }
      response = @connection.get("document-storage/json/2/docs", params)

      JSON.parse(response.body)[0]['BlobURLGet']
    end

    def attributes_json
      [{ "ID": @uuid,
         # "BlobURLGet": "",
         # "CurrentPage": 0,
         # "BlobURLGetExpires": "0001-01-01T00:00:00Z",
         # "Message": "",
         # "Success": true,
         # "Bookmarked": false,             
         "Version": 1, 
         "ModifiedClient": Time.now.strftime("%Y-%m-%dT%H:%M:%SZ"),
         "Type": "DocumentType",
         "VissibleName": File.basename(@name, ".*"),
         "Parent": "" }].to_json
    end
  end
end
