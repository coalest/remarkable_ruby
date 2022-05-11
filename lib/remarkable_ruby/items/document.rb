module RemarkableRuby
  class Document < Item
    def initialize(attrs: nil, client: nil, path: nil)
      super(attrs: attrs, client: client)

      @type = "DocumentType"
      @path = path
      @name = File.basename(path) if path
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
  end
end
