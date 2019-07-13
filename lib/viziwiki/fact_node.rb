class Viziwiki::FactNode
  @@roles = [:functor, :description, :edge, :role_operator, :main_operator]

  def initialize(role, name, render_text, description_list, functor_list)
    @role = role
    @name = name
    @render = render_text
    @description = description_list
    @functor = functor_list

    unless role in @@roles:
      raise TypeError, %Q{Creating fact with invalid role (#{@role}): #{inspect}}
  end

  def is_edge?
    @role == :edge
  end

  def is_main_operator?
    @role == :main_operator
  end

  def is_role_operator?
  end

  def is_functor?
  end

  def is_description?
  end

  def to_s
    @render if @render
    if @role == :edge
      %Q{~#{name}}
    elsif @role == :main_operator
      %Q{#{name}}
    else
      %Q{#{role}:#{name}}
    end
  end

  def inspect
    %Q{[#{role} : #{name} | #{render}][,#{description_list}][.#{functor}]}
  end
end
