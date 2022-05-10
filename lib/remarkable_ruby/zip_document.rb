module RemarkableRuby
  class ZipDocument
    attr_reader :document, :extension

    def initialize(document)
      @document = document
      @path_to_file = document.path
      @extension = File.extname(document.name).sub(".", "")
    end

    def dump
      uuid = document.uuid
      folder = Dir.mktmpdir(uuid)
      zip_path = Dir.tmpdir + "/#{uuid}.zip"
      input_filenames = ["#{uuid}.content", "#{uuid}.pagedata", "#{uuid}.#{extension}"]
      File.write(folder + "/#{uuid}.content", default_content.to_json)
      File.write(folder + "/#{uuid}.pagedata", "")
      FileUtils.cp(@path_to_file, folder + "/#{uuid}.#{extension}")
      Zip::File.open(zip_path, create: true) do |zipfile|
        input_filenames.each do |filename|
          zipfile.add(filename, File.join(folder, filename))
        end
      end
      FileUtils.remove_entry_secure(folder)
      zip_path
    end

    def default_content
      { extraMetadata: {},
        lastOpenedPage: 0,
        lineHeight: -1,
        fileType: extension,
        pageCount: 0,
        margins: 180,
        textScale: 1,
        transform: {} }
    end
  end
end
