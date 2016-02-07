require 'yaml'

white_lines_count = 0
spell_lines_count = 0
current_spell = {}
spells = []
current_line = 0

spells_lines_names = { 0 => :name, 1 => :level, 2 => :casting_time, 3 => :range, 4 => :components, 5 => :duration }

File.open( 'Spells - cleaned.txt', 'r' ) do |file|
  file.each_line do |line|

    # puts line.length
    current_line += 1

    if line.length == 2
      white_lines_count += 1
    else
      if spell_lines_count <= 5
        current_spell[ :start_line ] = current_line if spell_lines_count == 0
        current_spell[ spells_lines_names[ spell_lines_count ] ] = line.strip
        spell_lines_count += 1
      else
        current_spell[ :description ] = '' unless current_spell[ :description ]
        current_spell[ :description ] << line.strip
      end
    end

    # puts spell_lines_count

    if white_lines_count >= 2
      spells << current_spell
      current_spell = {}
      white_lines_count = 0
      spell_lines_count = 0
    end
  end
end

spells.each_entry do |entry|
  puts "#{entry[ :start_line ] } - #{entry[ :casting_time ].inspect}"
  entry[ :casting_time ].gsub!( 'Casting Time: ', '' ) if entry[ :casting_time ]
end

File.open( 'spell_database.yaml', 'w' ) do |file|
  file.puts spells.to_yaml
end