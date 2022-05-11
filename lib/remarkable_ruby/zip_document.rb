module RemarkableRuby
  class ZipDocument
    attr_reader :item

    def initialize(item)
      @item = item
      @path_to_file = item.path
    end

    # TODO: Break up this method into submethods
    def dump
      uuid = item.uuid
      folder = Dir.mktmpdir(uuid)
      zip_path = Dir.tmpdir + "/#{uuid}.zip"
      input_filenames = ["#{uuid}.content"]
      case item.type
      when "CollectionType"
        File.write(folder + "/#{uuid}.content", {})
      when "DocumentType"
        input_filenames.push("#{uuid}.pagedata", "#{uuid}.pdf")
        File.write(folder + "/#{uuid}.content", default_pdf_content.to_json)
        File.write(folder + "/#{uuid}.pagedata", "")
        FileUtils.cp(@path_to_file, folder + "/#{uuid}.pdf")
      end
      Zip::File.open(zip_path, create: true) do |zipfile|
        input_filenames.each do |filename|
          zipfile.add(filename, File.join(folder, filename))
        end
      end
      FileUtils.remove_entry_secure(folder)
      zip_path
    end

    def default_pdf_content
      { "extraMetadata": {},
        "lastOpenedPage": 0,
        "lineHeight": -1,
        "fileType": "pdf",
        "pageCount": 0,
        "margins": 180,
        "textScale": 1,
        "transform": {} }
    end
  end
end
