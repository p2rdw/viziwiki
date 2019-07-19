class Viziwiki::Fact
  def initialize
    @edge = nil
    @main_op = []
    @role_op = []

    @current_node = nil

    set_fact_name! nil
    set_location nil, nil, nil
  end


  def add_fact_node node
    if node.is_edge?
      if has_edge?
        raise TypeError, "trying to add a edge node: #{node} into an already edged fact: #{inspect}"
      else
        @edge = node
      end
    elsif node.is_main_operator?
      @main_op.push node
      @current_node = node
    elsif node.is_role_operator?
      @role_op.push node
      @current_node = node
    elsif node.is_functor? and @current_node
      @current_node.add_functor_node node
      @current_node = node
    elsif node.is_informative? and @current_node
      @current_node.add_informative_node node
    end
    node
  end


  def edge
    @edge
  end

  def main_op
    @main_op
  end

  def role_op
    @role_op
  end

  def name
    @name
  end

  def location
    [@file, @offset, @line]
  end





  def set_uuid! uuid
    set_fact_name! "Fact-#{uuid}"
  end

  def set_fact_name! name
    @name = name
  end

  def force_new_name! bot = nil
    set_uuid! ::Viziwiki.new_uuid
    if bot
      while not (bot.lock_or_fail! self)
        set_uuid! ::Viziwiki.new_uuid
      end
    end
  end

  def set_location file, offset, line
    @file = file
    @offset = offset
    @line = line
  end

  def set_edge edge
    @edge = edge
  end

  def add_main_op op
    @main_op.push op
  end

  def add_role_op op
    @role_op.push op
  end




  def valid?
    has_edge? and has_name? and @main_op.size > 0
  end

  def has_edge?
    @edge != nil
  end

  def has_name?
    @name != nil
  end


  def to_s
    # TODO?
    default_to_s
  end

  def default_to_s
    text = %Q{#{@main_op.first.to_s} #{@edge.to_s}}
    for op in @main_op[1..-1]
      text += %Q{ #{op.to_s}}
    end
    for op in @role_op
      text += %Q{ #{op.to_s}}
    end
    text
  end


  # TODO refactor all this shit
  def mediawiki_link
    return nil unless @name
    "[[#{@name}]]"
  end

  def fancy_mediawiki_link
    return nil unless @name
    Viziwiki::Fact.to_fancy_mediawiki_link @name
  end

  def self.to_fancy_mediawiki_link name
    "<sub>[[#{name}|#]]</sub>"
  end

  def self.fancy_mediawiki_link?
    Regexp.new "^<sub>\\[\\[.*\\]\\]<\/sub>$", Regexp::IGNORECASE
  end


end
