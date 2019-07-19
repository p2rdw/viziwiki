class Viziwiki::FactNode
  @@types = [:functor, :informative, :edge, :role_operator, :main_operator, :declaration, :delete, :add, :atag]


  def initialize type, name, declarations = nil
    @type = type
    if name.include? ':'
      @role, @actor = name.split ':'
    else
      @role = nil
      @actor = name
    end
    if declarations
      @role = apply_declarations declarations, @role
      @actor = apply_declarations declarations, @actor
    end
    @infos = []
    @functor = nil

    unless @@types.include? type
      raise TypeError, %Q{Creating fact with invalid type: #{type}. Valid types: #{@types} - #{inspect}}
    end
  end


  def apply_declarations declarations_hash, value
    value = table[value]  if value and (table.key? value)
    value
  end


  def type
    @type
  end

  def actor
    @actor
  end

  def role
    @role
  end

  def functor
    @functor
  end

  def informative_nodes
    @infos
  end




  def add_informative_node node
    @infos.push node
  end

  def add_functor_node node
    @functor = node
  end




  def is_edge?
    @type == :edge
  end

  def is_main_operator?
    @type == :main_operator
  end

  def is_role_operator?
    @type == :role_operator
  end

  def is_functor?
    @type == :functor
  end

  def is_informative?
    @type == :informative
  end

  def is_atag?
    @type == :atag
  end



  def atag!
    @type = :atag
  end



  def inspect
    text = "#{@type}<"
    text.concat "#{@role}:"                                 if @role
    text.concat "#{@actor}"
    text.concat ",#{@infos.map {|i| i.inspect}.join ','}"   if @infos.size > 0
    text.concat ".#{@functor.inspect}"                      if @functor
    text.concat ">"
    text
  end
end
