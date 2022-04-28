module RemarkableRuby
  class Document < Object
    # Download the zip file for a given document in the user's current directory
    def download
      file_name = "#{name}.zip"
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

    def delete
      payload = [{ ID: uuid, Version: version }]
      response = connection.put("/document-storage/json/2/delete", payload)
    end

    def highlights
      highlights = []
      download unless File.exists?("#{name}.zip")
      Zip::File.open("#{name}.zip") do |zip_file|
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
