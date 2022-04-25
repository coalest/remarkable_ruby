module RemarkableRuby
  class Folder < OpenStruct
    def initialize(attributes)
      attributes.merge!(Folder.defaults) if attributes.keys.count <= 2
      super
    end

    private

    def self.defaults
      { ID: SecureRandom.uuid,
        Version: 1,
        Message: "",
        Success: true,
        BlobURLGet: "",
        BlobURLExpires: "0001-01-01T00:00:00Z",
        ModifiedClient: Time.now.to_s,
        Type: "CollectionType",
        CurrentPage: 0,
        Bookmarked: false }
    end
  end
end
