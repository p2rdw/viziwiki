class Viziwiki::Fact
  def initialize(edge, main_operators, role_operators, context)
    @edge = edge
    @main_op = main_operators
    @role_op = role_operators

    set_fact_name nil
    set_location nil, nil, nil
    set_edge_template nil
  end


  def set_fact_name name
    @name = name
  end

  def set_location file, offset, line
    @file = fiile
    @offset = offset
    @line = line
  end

  def set_edge_template nil
    @edge_template = nil
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
    # if edge_template
    #   TODO implement to_s and inspect having in account @edge_template
    # else
    default_to_s
    # end
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
end
