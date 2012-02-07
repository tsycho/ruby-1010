
origfile = ARGV[0]
newfile = ARGV[1]

if origfile.nil? or newfile.nil?
	puts "Usage: ruby reduce1010.rb <origfile> <newfile>"
	return
end

file = File.new(origfile, "r")
vars = { "GLOBAL" => [] }
used_vars = [ "GLOBAL" ]
final_section = false

while (line = file.gets)
	value_str = ""
	
	if (line =~ /<note/i) || (line =~ /<link/i)
		next
	elsif line =~ /<willbe name="(.*)" value="(.*)"/i
		node = $1.strip
		vars[node] = []		
		value_str = $2.strip
		used_vars.push(node) if final_section
	elsif (line =~ /<sel value="(.*)"\/>/i) || (line =~ /<tabu(.*)/i) || (line =~ /<tcol(.*)/i)
		node = "GLOBAL"
		value_str = $1.strip
		final_section = true if (line =~ /<tabu(.*)/i)
		
		used_vars.push($1.strip) if line =~ /<tcol.*source="([^\s]*)"/i
		used_vars.push($1.strip) if line =~ /<tcol.*weight="([^\s]*)"/i
		if line =~ /<tabu.*breaks="([^\s]*)"/i			
			$1.strip.split(",").each { |b| used_vars.push(b.strip) unless used_vars.include?(b.strip) }
		end
		if line =~ /<tabu.*cbreaks="([^\s]*)"/i
			$1.strip.split(",").each { |b| used_vars.push(b.strip) unless used_vars.include?(b.strip) }
		end
	end
	
	#puts value_str
	
	if value_str != ""
		vars.each { |key, value| 
			if value_str =~ Regexp.new(key) && key!=node 
				vars[node].push(key) unless vars[node].include?(key)
			end
		}
	end
end
file.close

puts "Dependencies..."
vars.each { |k, v| puts "#{k}\t: #{v.join(', ')}" }
puts

####################

puts "Used vars: #{used_vars.join(", ")}"
gets
sleep 5
bfslist = used_vars.map { |v| v }

while !bfslist.empty?
	v = bfslist.pop
	puts "Popping /#{v}/"
	if vars[v].nil?
		puts "NOTE: #{v} not found in vars"
		next
	end
	
	vars[v].each { |dep| 
		unless used_vars.include?(dep)
			puts "Pushing dep: #{dep}"
			bfslist.push(dep)
			used_vars.push(dep)
		end
	}
end
puts "Used vars: #{used_vars.join(", ")}"

####################

file = File.new(origfile, "r")
outfile = File.new(newfile, "w")
while (line = file.gets)
	next if (line =~ /<willbe name="(.*)" value="(.*)"/i) && !used_vars.include?($1)
	outfile.puts line
end
file.close
outfile.flush
outfile.close
