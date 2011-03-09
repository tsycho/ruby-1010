require 'api1010'

ROOT_FOLDER = "G:/Asif/Work/Periodicals/Monthly/Credit Monthly/raw/"
sos_files = File.new(ROOT_FOLDER + "SOS-files.txt", "r").read

USERNAME = ENV['USERNAME_1010']
PASSWORD = ENV['PASSWORD_1010']
api = API1010.new(USERNAME, PASSWORD)
api.login
	
sos_files.split("\n").each { |line|
	line = line.strip
	
	puts line if line[0] == "#"
	next if line.empty? || line[0] == "#"
	break if line[0...4] == "quit"
	
	strs = line.split(":")
	file, outputfile, table = strs[0], strs[1], strs[2]
	
	puts "\n#{file}\t => #{outputfile}" + (table.nil? ? "" : " [#{table}]")
	api.run_query( { 
		:file => ROOT_FOLDER + file, 
		:table => table || 'pub.fin.lp.deep2',
		:outfile => ROOT_FOLDER + outputfile 
		} )
}

api.clear_cache