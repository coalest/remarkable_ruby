class Highlight
  attr_reader :color, :text, :length, :start

  def initialize(attrs)
    @color = attrs['color']
    @text = attrs['text']
    @length = attrs['length']
    @start = attrs['start']
  end
  
  def self.join_adjacent(highlights)
    highlights.sort_by!(&:start)
    adjacent_indexes(highlights).map do |first, last|
      merged_attributes = merge(highlights[first..last])
      new(merged_attributes)
    end
  end

  def self.adjacent_indexes(highlights)
    adjacent_highlights = []
    offset = 0
    bools = get_bools(highlights)
    while offset < highlights.length - 2
      next_false_index = bools[offset..-1].index(false) + offset
      adjacent_highlights << [offset, next_false_index]
      offset = next_false_index + 1
    end
    adjacent_highlights
  end

  def self.get_bools(highlights)
    bools = []
    highlights[0..-2].each_with_index do |hl, i|
      bools << hl.is_adjacent?(highlights[i + 1])
    end
    bools.push(false)
  end

  def self.merge(highlights)
    combined_text = highlights.map(&:text).join(' ')

    {
      'color' => highlights.first.color,
      'text' => combined_text,
      'length' => combined_text.length,
      'start' => highlights.first.start
    }
  end

  def is_adjacent?(highlight)
    first, second = self, highlight
    second.start - (first.length + first.start) <= 2
  end
end
