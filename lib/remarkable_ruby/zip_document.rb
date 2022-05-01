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
      
      folder = Dir.pwd + "/#{uuid}"
      Dir.mkdir(folder) unless File.exists?(folder)
      input_filenames = ["#{uuid}.content", "#{uuid}.pagedata", "#{uuid}.pdf"]
      File.write("#{uuid}/#{uuid}.content", @content.to_json)
      File.write("#{uuid}/#{uuid}.pagedata", "")
      FileUtils.cp(@file_name, uuid)
      FileUtils.mv("#{uuid}/#{@file_name}", "#{uuid}/#{uuid}.pdf")
      Zip::File.open("#{uuid}.zip", create: true) do |zipfile|
        input_filenames.each do |filename|
          zipfile.add(filename, File.join(folder, filename))
        end
      end
    end
  end
end
