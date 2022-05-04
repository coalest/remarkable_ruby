module RemarkableRuby
  class Folder < Item
    def initialize(attrs: nil, client: nil, path: nil)
      @type = "CollectionType"
      super
    end
  end
end
