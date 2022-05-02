module RemarkableRuby
  class Folder < Object
    def initialize(attrs: nil, client: nil, path: nil)
      @type = "CollectionType"
      super
    end
  end
end
