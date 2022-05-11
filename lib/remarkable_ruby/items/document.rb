module RemarkableRuby
  class Document < Item
    def initialize(attrs: nil, client: nil, path: nil)
      super(attrs: attrs, client: client)

      @type = "DocumentType"
      @path = path
      @name = File.basename(path) if path
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

    private

    def get_blob_url
      params = { doc: uuid, withBlob: true }
      response = @connection.get("document-storage/json/2/docs", params)
      JSON.parse(response.body).first['BlobURLGet']
    end
  end
end
