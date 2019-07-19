require 'viziwiki/fact'
require 'viziwiki/fact_node'




class Viziwiki::Context
  def log
    ::Viziwiki::log
  end


  def initialize
    @declarations = {}

    @full_stack = []
    @fact_stack = []

    @paragraph_context = []
    @section_context = [[]]
    @section_context_idx = 0

    @current_fact = nil
  end


  def inspect
    { facts:                @fact_stack \
    , paragraph_context:    @paragraph_context \
    , section_context:      @section_context \
    , section_context_idx:  @section_context_idx \
    , current_fact:         @current_fact \
    }
  end




  def new_sentence page, offset, line
    @current_fact = ::Viziwiki::Fact.new
    @current_fact.set_location page, offset, line
  end


  # returns the fact of the ended sentence, if a fact is found, nil otherwise
  def end_sentence
    return nil unless @current_fact

    if @current_fact.has_edge?
      expand_fact_with_context @current_fact
      @fact_stack.push @current_fact
    else
      # TODO what to do...? auto atag them? make a note, make a phrase...
      #     just ignore?
      log.debug "sentence ended without edge: #{inspect}"
    end
    @full_stack.push @current_fact
    @current_fact
  end


  def end_paragraph
    # clean paragraph
    @paragraph_context = []
  end


  def new_section level
    # close the sections
    l = @section_context_idx
    while l > level
      end_section l
      l -= 1
    end
    # if need, create levels
    while @section_context.size <= level
      @section_context.push []
    end
    # set section_context_idx and clean the context
    @section_context_idx = level
    end_section @section_context_idx
  end

  def end_section level
    # clean section
    @section_context[level] = []
    level
  end




  def expand_fact_with_context fact
    # iterate section par
    # check current par
    l = 0
    while l <= @section_context_idx
      expand_fact_with @section_context[l], fact
      l += 1
    end
    expand_fact_with @paragraph_context, fact
  end

  def expand_fact_with context, fact
    for f in context
      node = if f.role == nil
        # atag
        Viziwiki::FactNode.new :role_operator, "atag:#{f.actor}", nil
      else
        Viziwiki::FactNode.new :role_operator, "#{f.role}:#{f.actor}", nil
      end
      # we pass nil as table because already applied, and not I(I()) = I()
      fact.add_fact_node node
    end
  end




  # /^[0-9]?[+]/    add role:actor link into section level context or add link into [atag:link]
  # /^[_]/          add role:actor link into paragraph context or add link into [atag:link]
  # /^[0-9]?[!]/    force such role to have only one value
  # /^[0-9]?[_]/    delete such role to have only one value
  # /^[=]/          names are plain variables with no scope

  # /.functor/
  # /,informative/
  # /~edge/
  # /role:actor/
  # /actor/
  def new_link link, text
    log.debug "CONTEXT new link #{link} #{text}"
    value = link
    level = 0
    type = nil

    return unless value and value.size > 0

    if (text == '#') and (value =~ /^Fact-[a-z0-9]{8}-[a-z0-9]{4}-[a-z0-9]{4}-[a-z0-9]{4}-[a-z0-9]{12}$/)   # TODO refacor
      # if it is a mark '#' fact link, do not add it
      # TODO idea: allow non to be parsed links with name '#'?
      @current_fact.set_fact_name! value
      log.debug "CONTEXT set name current fact #{value}"
      return
    end


    if value =~ /^[_]/
      # add to this paragraph
      value = value[1..-1]
      fn = Viziwiki::FactNode.new :add, value, @declarations
      @paragraph_context.push
      log.debug "CONTEXT add follow vizilink #{value} into the paragraph context"
      return

    elsif value =~ /^[0-9]?[+]/
      # add to the next N parent sections
      level = value.first
      if level == '+'
        level = 0
        value = value[1..-1]
      else
        level = level.to_i
        value = value[2..-1]
      end
      fn = Viziwiki::FactNode.new :add, value, @declarations
      max_level = max(@section_context - level, 0)
      @section_context[max_level].push fn
      log.debug "CONTEXT add follow vizilink #{value} into the #{max_level} section level"
      return

    # -role:        delete all role
    # -role:value   delete all role:value
    # -:value        delete all value
    # -atag         delete atag
    elsif value =~ /^[0-9]?[-]/
      # delete
      level = value.first.to_i
      value = value[1..-1]
      value = value[1..-1] if value.first == '!'
      delete_type = nil
      if not value.contains? ':'
        delete_type = :remove_atag
      else
        role, actor = value.split ':'
        if actor == nil
          delete_type = :remove_role
        elsif role  == nil
          delete_type = :remove_value
        else
          delete_type = :remove_role_and_value
          actor = value
          role = nil
        end
      end
      delete delete_type, level, role, actor
      log.debug "CONTEXT delete follow vizilink #{value} into the #{max_level} section level"
      return

      # !role:value   delete all values for such role and set it to value
    elsif value =~ /^[0-9]?[!]/
      # delete and set monly once
      level = value.first.to_i
      value = value[1..-1]
      value = value[1..-1] if value.first == '!'

      if value.contains? ':'
        role, actor = value.split ':'
        if role != nil
          deepest_level = delete :remove_role, @section_context, role, nil
          fn = Viziwiki::FactNode.new :add, value, @declarations
          if deepest_level == -1
            @paragraph_context.push fn
          else
            @section_context[deepest_level].push fn
          end
        end
      end
      log.debug "CONTEXT delete follow vizilink #{value} into the #{max_level} section level"
      return

    elsif value =~ /^[=]/
      # var
      value = value[1..-1]
      type = :declaration
      @declarations[value] = text
      return

    elsif value =~ /^[.]/
      value = value[1..-1]
      type = :functor

    elsif value =~ /^[,]/
      value = value[1..-1]
      type = :informative
    end


    if type == nil
      role_op_o = value.rindex ':'
      type = if role_op_o and role_op_o > 0
        :role_operator
      elsif value[0] == '~'
        value = value[1..-1]
        :edge
      else
        # empty role operand... [[:ActorLink]]
        value = value[1..-1] if role_op_o == 0
        :main_operator
      end
    end

    fact_node = ::Viziwiki::FactNode.new type, value
    @current_fact.add_fact_node fact_node
  end


  def delete delete_type, level, actor, role
    deepest_level = nil

    r = delete_from_context @paragraph_context, delete_type, f, actor, role
    deepest_level = -1 if r < 0

    next_level = @section_context
    last_level = max(@section_context - level, 0)
    while next_level >= last_level
      r = delete_from_context @section_context[next_level], delete_type, f, actor, role
      deepest_level = next_level if r < 0
      next_level -= 1
    end
    deepest_level
  end


  def delete_from_context c, delete_type, actor, role
    size_0 = c.size
    if delete_type == :remove_atag
      c.delete_if! { |f| f.is_atag? and f.actor == actor }
    elsif delete_type == :remove_role
      c.remove_if { |f| f.is_role_operator? and f.role == role}
    elsif delete_type == :remove_value
      c.remove_if { |f| f.is_role_operator? and f.actor == actor}
    elsif delete_type == :remove_role_and_value
      c.remove_if { |f| f.is_role_operator? and f.role == role and f.actor == actor}
    end
    c.size - size_0
  end

end
