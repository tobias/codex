require 'redcloth'

class Codex::Content
  START_SLIDE = %{<div class="slide">\n}
  END_SLIDE   = %{</div>\n}
  BETWEEN_SLIDES = END_SLIDE + "\n" + START_SLIDE
  HEADING_MARKER = 'h1\. '
  REPEAT_SLIDE_MARKER = '&::'
  SPLIT_REGEX = /^(#{HEADING_MARKER}|#{REPEAT_SLIDE_MARKER})/
  
  def initialize(original)
    @original = original.sub(/__END__.*/m, '').gsub(/__SKIP__.*?__ENDSKIP__/m, '')
  end

  def to_html
    textile = Codex::Filters.instance.filter_all(@original)
    slides = split_into_slides(textile)
    content = join_slides(slides)
    html = RedCloth.new(content).to_html
  end
  
  def split_into_slides(textile)
    delims_and_slides = textile.split(SPLIT_REGEX)
    #ditch anything before first delim
    delims_and_slides[1..-1].inject([]) do |accum, s|
      last_el = accum.pop
      if last_el.is_a?(String)
        accum << [last_el, s]
      else
        accum << last_el << s
      end
      accum
    end
  end

  def join_slides(slides)
    result = []
    slides.each_with_index do |slide_data, index|
      delim, slide = slide_data
      result << START_SLIDE << "\nh1. "
      result << slides[index - 1][1] if delim == REPEAT_SLIDE_MARKER and index > 0
      result << slide << END_SLIDE
    end
    result.join
  end

end
