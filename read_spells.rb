require 'yaml'

spells_lines_names = { 0 => :name, 1 => :level, 2 => :casting_time, 3 => :range, 4 => :components, 5 => :duration }
spells = []

COMPONENTS = %w( V S M )

File.open( 'Spells - cleaned.txt', 'r' ) do |file|

  spells_lines_start_lines = []
  current_line = 0

  file.each_line do |line|
    current_line += 1
    if line.strip =~ /Casting Time: \d+ \w+/
      spells_lines_start_lines << current_line - 2
    end
  end

  file.seek( 0, :SET )
  current_line = 0
  current_spell = {}
  spell_lines_count = 0
  spells_lines_start_lines.shift # Dont process the first line as it is not following something
  spells_lines_start_lines = spells_lines_start_lines.map{ |e| e-1 } # Also the end line must be the line before the start of the spell.

  file.each_line do |line|

    current_line += 1

    if spell_lines_count <= 5
      current_spell[ :start_line ] = current_line if spell_lines_count == 0
      current_spell[ spells_lines_names[ spell_lines_count ] ] = line.strip
      spell_lines_count += 1
    else
      current_spell[ :description ] = [] unless current_spell[ :description ]
      current_spell[ :description ] << line.strip unless line.strip.length == 0
    end

    if spells_lines_start_lines.include?( current_line )
      spell_lines_count = 0
      spells << current_spell
      current_spell = {}
    end
  end
end

spells.each_entry do |entry|
  # puts "#{entry[ :start_line ] } - #{entry[ :casting_time ].inspect}"
  entry[ :casting_time ].gsub!( 'Casting Time: ', '' ) if entry[ :casting_time ]
  entry[ :duration ].gsub!( 'Duration: ', '' ) if entry[ :duration ]
  entry[ :components ].gsub!( 'Components: ', '' ) if entry[ :components ]

  if entry[ :level ] =~ /cantrip/
    entry[ :school ] = entry[ :level ].match( /(\w+)/ )[1].downcase.to_sym
    entry[ :level ] = 0
    entry[ :cantrip ] = true
  else
    result = entry[ :level ].match( /(\d+)[a-z\-]+ (\w+)(.*)/ )
    entry[ :level ] = result[1].to_i
    entry[ :school ] = result[2].downcase.to_sym
    entry[ :ritual ] = true if result[3]
  end

  components = entry[ :components ].split( /[,()]/ ).map{ |e| e.strip }
  entry[ :components ] = []
  until components.empty?
    c = components.shift
    if COMPONENTS.include?( c )
      entry[ :components ] << c
    else
      entry[ :material_components ] = c.capitalize
    end
  end

  entry[ :range ].gsub!( 'Range: ', '' ) if entry[ :range ]

  range_in_feet = entry[ :range ].match( /(\d+) feet/ )
  range_in_feet = range_in_feet[ 1 ] if range_in_feet

  range_in_yards = entry[ :range ].match( /(\d+) miles?/ )
  range_in_yards = range_in_yards[ 1 ] if range_in_yards
  range_in_feet = range_in_yards.to_i * 3 if range_in_yards

  range_in_miles = entry[ :range ].match( /(\d+) miles?/ )
  range_in_miles = range_in_miles[ 1 ] if range_in_miles
  range_in_feet = range_in_miles.to_i * 5280 if range_in_miles

  entry[ :range_in_feet ] = range_in_feet ? range_in_feet.to_i : 0

  # ranges = [ entry[ :range ], entry[ :range_in_feet ] ].join( ' - ' )
  # puts ranges

end

File.open( 'spell_database.yaml', 'w' ) do |file|
  file.puts spells.to_yaml
end