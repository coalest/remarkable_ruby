module RemarkableRuby
  class Folder < Object
    def initialize(attrs, connection)
      attrs.merge!(Folder.defaults) if attrs.keys.count <= 2
      super
    end

    private

    attr_reader :client

    def self.defaults
      { 
        ID: SecureRandom.uuid,
        Version: 1,
        Message: "",
        Success: true,
        BlobURLGet: "",
        BlobURLExpires: "0001-01-01T00:00:00Z",
        ModifiedClient: Time.now.to_s,
        Type: "CollectionType",
        CurrentPage: 0,
        Bookmarked: false 
      }
    end
  end
end
