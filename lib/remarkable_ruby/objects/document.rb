module RemarkableRuby
  class Document < Object
    # Download the zip file for a given document in the user's current directory
    def download
      file_name = "#{uuid}.zip"
      return if File.exists?(file_name)

      params = { doc: @uuid, withBlob: true }
      response = @connection.get("document-storage/json/2/docs", params)

      dl_link = extract_link(response)
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
      payload = [{ "ID": uuid, "Type": type, "Version": version }]
      response = @connection.put("document-storage/json/2/upload/request", payload)
      put_url = JSON.parse(response.body).first["BlobURLPut"]

      # Workaround to not use multipart
      ZipDocument.new(self).dump
      file_data = Base64.encode64(File.read("#{uuid}.zip"))
      response = @connection.put(put_url, file_data) do |r|
        r.headers['Content-Type'] = ""
      end

      payload = [attributes].to_json
      response = @connection.put("document-storage/json/2/upload/update-status", payload)
    end

    private

    def extract_link(response)
      JSON.parse(response.body)[0]['BlobURLGet']
    end

    def attributes
      { "ID": @uuid,
         # "BlobURLGet": "",
         # "CurrentPage": 0,
         # "BlobURLGetExpires": "0001-01-01T00:00:00Z",
         # "Message": "",
         # "Success": true,
         # "Bookmarked": false,             
         "Version": 1, 
         "ModifiedClient": Time.now.strftime("%Y-%m-%dT%H:%M:%SZ"),
         "Type": "DocumentType",
         "VissibleName": @name.split(".").first,
         "Parent": "" }
    end
  end
end
