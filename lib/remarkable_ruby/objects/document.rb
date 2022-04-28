module RemarkableRuby
  class Document < Object
    # Download the zip file for a given document in the user's current directory
    def download
      params = { doc: @uuid, withBlob: true }
      response = @connection.get("document-storage/json/2/docs", params)

      dl_link = extract_link(response)
      streamed = []
      @connection.get(dl_link) do |req|
        req.options.on_data = Proc.new { |chunk| streamed << chunk }
      end

      new_file_name = "#{name}.zip"
      File.write(new_file_name, streamed.join)
      new_file_name
    end

    def delete
      payload = [{ ID: uuid, Version: version }]
      response = connection.put("/document-storage/json/2/delete", payload)
    end

    def highlights
      highlights = []
      download(uuid) unless File.exists?("#{uuid}.zip")
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

    private

    def extract_link(response)
      JSON.parse(response.body)[0]['BlobURLGet']
    end
  end
end
