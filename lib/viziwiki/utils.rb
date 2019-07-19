class Viziwiki::Utils

  def self.tag_section tags, section_name = nil, level = 2
    section_name = 'tags' unless section_name
    header = %Q{
  #{header section_name, level}
}
    header + tags.map { |tag| "* [[#{tag}]]" }.join("\n")
  end


  def self.header title, level = 2
    ht = ''.rjust level, '='
    "#{ht} #{title} #{ht}"
  end

end
