
require 'viziwiki/context'
require 'cgi'




class Viziwiki::Mediawiki::Parser
  def log
    ::Viziwiki::log
  end


  # normalize text (fact to parser)
  @@section_elements = %w(h1 h2 h3 h4 h5 h6 h7 h8)
  @@end_paragraph_elements = %w(div p li ol ul) + @@section_elements
  @@end_sentence_elements = @@end_paragraph_elements + %w(blockquote)
  @@vizi_links = %w(a)
  @@vizi_elements = @@vizi_links + @@end_sentence_elements


  def initialize bot = nil
    @bot = bot
    # access to the wiki is needed if we want the normalizer
    # to create new facts when a fact has been updated (desirable)
    reset_context!
    init_parse nil, nil, nil
  end


  def init_parse mediawiki, html, page
    # the mediawiki raw text
    @mediawiki = ''
    # \invariant @mediawiki[0..@mediawiki_until] has been normalized into @normalized
    @mediawiki_until = 0

    # string where the normalized text is generated
    @normalized = ''

    # the parsing actually only checks the promising elements
    # \invariant doc.css @@vizi_elements[0..@current_node_idx] have been parsed
    @current_node_idx = 0

    @created_new_sentence = false

    @html = html
    @mediawiki = mediawiki
    @page = page
  end


  def parsed_vizi_element!
    @current_node_idx += 1
  end


  def reset_context!
    # context, which is a kind of evaluator for the vizi elements
    # you place operands, and do queries with the object
    @context = Viziwiki::Context.new
    @fact_update = {}
    @new_facts = []
  end


  def normalized_text
    @normalized
  end

  def context
    @context
  end

  def updated_facts
    @fact_update
  end

  def new_facts
    @new_facts
  end

  # return the text normalized and parse the vizifacts into the context
  # WARNING if you want the proper parser and context of a normalized page:
  # you need to parse the normalize page! as the offsets are not the same
  def parse mediawiki, html, page
    log.debug "init parsing: #{mediawiki}"

    init_parse mediawiki, html, page
    doc = Nokogiri::HTML(@html)
    parse_node_r doc
    @normalized.concat @mediawiki[@mediawiki_until..-1] # copy the remaining...
    true
  end


  def parse_node_r node
    return unless node
    log.debug "#{@normalized} ... parsing node #{node}"
    parse_node node
    node.children.each { |c| parse_node_r c}
  end


  def parse_node node
    return unless node
    log.debug "PARSE parse_node #{(vizi_link? node).inspect}: #{node}"

    if node.text?
      end_sentence              if text_end_sentence? node.text
    elsif node.element?
      name = node.node_name
      end_sentence              if @@end_sentence_elements.include? name
      end_paragraph             if @@end_paragraph_elements.include? name
      new_section name[1].to_i  if @@section_elements.include? name
      parse_vizi_link node      if vizi_link? node
      parsed_vizi_element!      if @@vizi_elements.include? name
    end
  end


  def parse_vizi_link element
    if @created_new_sentence == false
      @created_new_sentence = true
      offset, line = place_cursor_to_vizi_link element
      @context.new_sentence @page, offset, line
    end

    log.debug "PARSE parse_vizi_link: #{element}"

    fact_node = @context.new_link (vizi_link_title element), element.text

    # when we found and edge, we place the cursor in front of it
    # this way, when the sentence ends, we can append directly the #fact link
    place_cursor_to_vizi_link element if fact_node and fact_node.is_edge?

    return fact_node
  end



  def new_section level
    @context.new_section level
  end

  def end_paragraph
    @context.end_paragraph
  end


  def end_sentence
    fact = @context.end_sentence
    if fact and (fact.has_edge?)
      # do something
      if fact.has_name?
        log.debug "PARSE end_sentence fact already has a name #{fact.name}"
        old_name = fact.name
        # we need a bot wiki to query whether the fact has changed or not
        if @bot and (not @bot.fact_seq old_name, fact)  # compare semantically equal, so ignore name and see all it-s identical or not
          fact.force_new_name! @bot
          @fact_update[old_name] = fact.name
          text = Viziwiki::Fact::to_fancy_mediawiki_link old_name

          # if has change update
          if @normalized.end_with? text
            @normalized = @normalized[0..-(text.size+1)]
            log.debug "remove fact link ::: #{@normalized}"
          else
            raise TypeError, "parsed #-fancy named fact: #{old_name}, but cannot be found before the edge"
          end
          @normalized.concat fact.fancy_mediawiki_link
          log.debug "updated fact into #{fact.fancy_mediawiki_link} ::: #{@normalized}"
        end
        # if fact hasn-t change, we have already parsed the [[Fact-iwlink|#]]
      else
        fact.force_new_name! @bot
        @new_facts.push fact
        @normalized.concat fact.fancy_mediawiki_link
        log.debug "new fact #{fact.fancy_mediawiki_link} ::: #{@normalized}"
      end
    end
    # otherwise do not anything
    @created_new_sentence = false
    fact
  end



  # get the location of this html element in the @cn_mediawiki string
  # WARNING it works only if incrementals calls, i.e. element is the lastest of all the previous get_location <elements> passed as a par
  # returns [offset, line]
  def place_cursor_to_vizi_link link
    text = link.text
    page = vizi_link_title link
    log.debug "PARSE place_cursor_to_vizi_link #{page} | #{text}"

    # get offset of the link
    offset = if wikimedia_similar text, page
      a = get_offset_wlink page
      b = get_offset_wlink_text page, text
      [a, b].select { |x| x != nil }.min
    else
      get_offset_wlink_text page, text
    end

    if offset == nil
      #raise TypeError, "our typing assumptions weren't good at all"
      log.debug "PARSE not found link that should be with the page #{@page} follow html: #{@html}"
      return [nil, nil]
    elsif offset > 0
      @normalized.concat @mediawiki[@mediawiki_until..offset - 1]
      @mediawiki_until = offset
      log.debug "write until offset #{offset} ::: #{@normalized}"
    end
    [@mediawiki_until, @mediawiki.lines.size]
  end

  def wikimedia_similar a, b
    0 == (a =~ (wikimedia_similar_regexp b))
  end

  def wikimedia_similar_regexp text
    reg_text = text.gsub /[ _]/, '[ _]'
    Regexp.new reg_text, Regexp::IGNORECASE
  end

  def get_offset_wlink link
    get_offset_link "#{link}"
  end

  def get_offset_wlink_text link, text
    get_offset_link "#{link}\\|#{text}"
  end

  def get_offset_link value
    get_offset "\\[\\[#{value}\\]\\]"
  end

  def get_offset text
    o = (@mediawiki[@mediawiki_until..-1] =~ (wikimedia_similar_regexp text))
    o += @mediawiki_until if o
    o
  end



  def link? node
    node and node.node_name == 'a'
  end


  def vizi_link? element
    begin
      return false unless link? element
      vizi_link_title element
    rescue => e
      false
    end
  end

  def vizi_link_title element
    value = element.attributes['href'].value
    if value.start_with? '/w/index.php?'
      value = value['/w/index.php?'.size .. -1]
      pvalue = CGI::parse value
      return nil unless pvalue['section'].empty?
      value = pvalue['title'].first
    elsif value.start_with? '/w/index.php/'
      value = value['/w/index.php?'.size .. -1]
    else
      raise TypeError, "vizi_link_title unexpected element #{element}"
    end

    if value and value.size > 0
      value
    else
      nil
    end
  end


  def text_end_sentence?(text)
    text =~ /(\.[ \n\t]|\.\&nbsp\;|\.$)/
  end

end
