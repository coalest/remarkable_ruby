module RemarkableRuby
  class Folder < Object
    def initialize(attrs: nil, connection: nil)
      attrs.merge!(defaults) if attrs.keys.count <= 2
      super
    end
  end
end
