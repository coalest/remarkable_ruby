module RemarkableRuby
  class Folder < Item
    def initialize(attrs: nil, client: nil, name: nil, parent: nil)
      super(attrs: attrs, client: client)

      @name = name if name
      @parent = parent if parent
      @type = "CollectionType"
    end
  end
end
