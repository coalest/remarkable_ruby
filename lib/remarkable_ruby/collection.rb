module RemarkableRuby 
  class Collection
    def self.from_response(response, type)
      body = JSON.parse(response.body)
      new(files: body.map{ |attrs| type.new(attrs) })
    end

    def initialize(files)
      @files = files
    end
  end
end
