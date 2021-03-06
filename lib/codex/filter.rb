require 'singleton'

module Codex 
  # Filter is an abstract class for user defined filters.
  # It lets them declare the tag they wish to use.
  # When declaring a tag, it also registers with Filters.
  class Filter
    attr_accessor :tag
    def self.tag(tag)
      @tag = tag
      (Filters.instance)[tag] = self.new
    end
  end

  # Filters contains a hash of all loaded filters. It does all parsing of the input file
  # and send chunks to be filtered to the individual filters.
  class Filters
    include Singleton
    attr_accessor :filter_file_tags, :filter_inline_tags, :filter_inline_end_tags, :log
    
    def []=(idx,val)
      @filters[idx] = val
    end
    
    def [](idx)
      @filters[idx]
    end

    # Parse the input text and parse chunks over to filters when encountering tags
    def filter_all(text)
      state = :copying
      result = []
      tagged_lines = []
      tag = args = nil
      text.split(/\n/).each do |line|
        case state
        when :copying
          if line =~ inline_tag
            tag = $1
            args = $2.strip
            state = :inside_tag
          elsif line =~ single_tag
            tag = $1
            args = $2.strip
            result << @filters[tag.to_sym].filter_single(args)
          else
            result << line
          end
        when :inside_tag
          if line =~ /^:end(inline#{tag}|#{tag})?(\s.*)?$/ # :endinlinewhatever, :endwhatever or just plain :end
            result << @filters[tag.to_sym].filter_inline(tagged_lines.join("\n"),args)
            tagged_lines = []
            state = :copying
          else
            tagged_lines << line
          end
        end
      end

      result.join("\n")
    end
    
    # Creates instance and loads all the user-defined filters in the generated filter/ subdirectory
    private
    def initialize
      @filters = {}
    end
    
    # Create regular expression to match single tags (tags with no end tag)
    def single_tag
      @single_tag_regex = tag_regexp if @single_tag_regex.nil?
      @single_tag_regex
    end

    # Create regular expression to match inline tags. By convention these are all prefixed "inline"
    def inline_tag
      @inline_tag_regex = tag_regexp("inline") if @inline_tag_regex.nil?
      @inline_tag_regex
    end
    
    # Does the actually work of creating matcher regular expressions
    def tag_regexp(prefix = "")
      Regexp.new("^:#{prefix}(" + (@filters.map { |tag,filter| tag.to_s }).join('|') + ")(.*)")
    end
  end
end