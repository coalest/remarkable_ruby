require 'ostruct'

class Highlight < OpenStruct
  class << self
    def join_adjacent(highlights)
      highlights = highlights.sort_by(&:start)
      adjacent_indexes(highlights).map do |first, last|
        merged_attributes = merge(highlights[first..last])
        new(merged_attributes)
      end
    end

    private

    def adjacent?(highlight_1, highlight_2)
      highlight_2.start - (highlight_1.length + highlight_1.start) <= 2
    end

    def adjacent_indexes(highlights)
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

    def get_bools(highlights)
      bools = []
      highlights[0..-2].each_with_index do |hl, i|
        bools << adjacent?(hl, highlights[i + 1])
      end
      bools.push(false)
    end

    def merge(highlights)
      combined_text = highlights.map(&:text).join(' ')

      {
        'color' => highlights.first.color,
        'text' => combined_text,
        'length' => combined_text.length,
        'start' => highlights.first.start
      }
    end
  end
end
