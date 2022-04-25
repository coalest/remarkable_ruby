module RemarkableRuby 
  class Collection
    def self.from_response(response)
      body = JSON.parse(response.body)
      new(body.map do |attrs|
        case attrs['Type']
        when "CollectionType" then Folder.new(attrs)
        when "DocumentType"   then Document.new(attrs) 
        else                       OpenStruct.new(attrs)
        end
      end)
    end

    def initialize(contents)
      @contents = contents
    end
  end
end
