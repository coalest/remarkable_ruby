module RemarkableRuby
  class Folder < Object
    def initialize(attrs: nil, connection: nil, path: nil)
      @type = "CollectionType"
      super
    end
  end
end
