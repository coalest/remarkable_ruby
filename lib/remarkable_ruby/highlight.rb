# class Highlight
#   def initialize(hash)
#     @color = hash['color']
#     @text = hash['text']
#     @length = hash['length']
#     @start = hash['start']
#   end

#   def merge(highlight)
#     first, second = [self, highlight].sort_by(&:start)
#     return unless second.start - (first.length + first.start) <= 2

#     {'color' => first.color,
#      'text' => first.text + ' ' + second.text,
#      'length' => first.length + second.length + 1,
#      'start' => first.start}
#   end
# end
