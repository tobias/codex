require 'redcloth'

class Codex::Content
  START_SLIDE = %{<div class="slide">\n}
  END_SLIDE   = %{</div>\n}
  BETWEEN_SLIDES = END_SLIDE + "\n" + START_SLIDE
  HEADING_MARKER = 'h1'
  REPEAT_SLIDE_MARKER = '&::'
  SPLIT_REGEX = /^(#{HEADING_MARKER}|#{REPEAT_SLIDE_MARKER})/
  
  def initialize(original)
    @original = original.sub(/__END__.*/m, '').gsub(/__SKIP__.*?__ENDSKIP__/m, '')
  end

  def to_html
    textile = Codex::Filters.instance.filter_all(@original)
    slides = split_into_slides(textile)
    slides = repeat_slides(slides)
    content = join_slides(slides)
    html = RedCloth.new(content).to_html
  end
  
  def split_into_slides(textile)
    delims_and_slides = textile.split(SPLIT_REGEX)
    delims_and_slides[1..-1].inject([]) do |accum, s|
      last_el = accum.last
      if last_el.is_a?(String)
        accum.pop
        accum << [last_el, s]
      else
        accum << s
      end
      accum
    end
  end
  
  def repeat_slides(slides)
    result = []
    slides.each_with_index do |slide_data, index|
      delim, slide = slide_data
      slide = result[index - 1] + slide if delim == REPEAT_SLIDE_MARKER and index > 0
      result << slide
    end
    result
  end
  
  def join_slides(slides)
    result = []
    slides.each do |slide|
      result << START_SLIDE << "\nh1" << slide << END_SLIDE
    end
    result.join
  end

end
