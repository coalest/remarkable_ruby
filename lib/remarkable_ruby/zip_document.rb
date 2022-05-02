module RemarkableRuby
  class ZipDocument
    attr_reader :metadata
    def initialize(document)
      @content = { "extraMetadata": {},
                   "lastOpenedPage": 0,
                   "lineHeight": -1,
                   "fileType": "pdf",
                   "pageCount": 0,
                   "margins": 180,
                   "textScale": 1,
                   "transform": {} }
      @metadata = { "deleted": false,
                    "lastModified": Time.now.strftime("%Y-%m-%dT%H:%M:%SZ"),
                    "ModifiedClient": Time.now.strftime("%Y-%m-%dT%H:%M:%SZ"),
                    "metadatamodified": false, 
                    "modified": false,
                    "Parent": "",
                    "pinned": false,
                    "synced": true,
                    "Type": "DocumentType",
                    "Version": 1,
                    "ID": document.uuid,
                    "VissibleName": document.name }
      # @pagedata = nil
      @document = document
      @file_name = document.name
    end

    def dump
      uuid = @document.uuid
      folder = Dir.mktmpdir(uuid)
      zip_path = Dir.tmpdir + "/#{uuid}.zip"
      input_filenames = ["#{uuid}.content", "#{uuid}.pagedata", "#{uuid}.pdf"]
      File.write(folder + "/#{uuid}.content", @content.to_json)
      File.write(folder + "/#{uuid}.pagedata", "")
      FileUtils.cp(@file_name, folder + "/#{uuid}.pdf")
      Zip::File.open(zip_path, create: true) do |zipfile|
        input_filenames.each do |filename|
          zipfile.add(filename, File.join(folder, filename))
        end
      end
      FileUtils.remove_entry_secure(folder)
      zip_path
    end
  end
end
