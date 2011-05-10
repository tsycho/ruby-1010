require 'net/http'
require 'uri'
require 'json'
require 'xmlsimple'

module URL1010
	URL_1010_LOGIN = "http://www2.1010data.com/"
	
	def login_url(uid, password)
		URL_1010_LOGIN + "cgi-bin/gw.k?api=login&apiversion=2" + "&uid=#{uid}" + "&pswd=#{password}" + "&kill=yes"
	end
	
	def get_url(api, uid, password, sid)
		URL_1010_LOGIN + "cgi-bin/gw.k?api=#{api}&apiversion=2" + "&uid=#{uid}" + "&pswd=#{password}" + "&sid=#{sid}"
	end
end

class API1010	
	include URL1010
	
	# Constants
	MAX_RETRIES = 20
	WRAP_1010_TAG = 'response_1010'
	PROXY = URI.parse("http://proxy.jpmchase.net:8443")
	DEFAULT_SEPARATOR = ","
	
	# Instance variables
	attr_reader :uid, :sid, :password
		
	def initialize(uid, password)
		@uid = uid
		@password = password
	end
	
	def login
		puts "Logging in to 1010..."
		run_1010( login_url(@uid, @password) ) do |json|				
			@sid = json["sid"]
			@password = json["pswd"]
			puts "Login successful."
		end
	end	
	
	def run_query(options)
		tableName = options[:table] || 'pub.fin.lp.histplus'
		
		if !options[:xml].nil?
			query_xml = options[:xml]
		elsif !options[:file].nil?
			query_xml = File.new( options[:file], "r").read
		else
			puts "Invalid options - should have either :xml or :file filled"
			return
		end
		
		url = get_url("query", @uid, @password, @sid)
		body = "<name>" + tableName + "</name>\n" + "<ops>\n" + query_xml + "</ops>"
		
		attempts = 1
		print "Running query..."
		
		while attempts < MAX_RETRIES
			should_retry = run_1010(url, body) do |json|
				# Generate XML query to retrieve results			
				body_xml = get_data_1010_query(json, options)
				url = get_url("getdata", @uid, @password, @sid)
				
				xml_params = { 'GroupTags' => { 'cols'=>'th', 'tr'=>'td', 'data'=>'tr' } }
				run_1010(url, body_xml, xml_params) do |json, xml|
					sep = options[:separator] || DEFAULT_SEPARATOR
					out = options[:outfile].nil? ? $stdout : File.open(options[:outfile], "w")
						
					out.write json['table']['cols'].map { |col| col["content"] }.join(sep).gsub("\n", ' ') + "\n"
					out.write json['table']['cols'].map { |col| col["name"] }.join(sep) + "\n"
					out.write json['table']['data'].map { |tr| tr["td"].join(sep) }.join("\n").gsub('{}', '')
					
					out.flush
					out.close unless options[:outfile].nil?
					
					puts "done"
					return json
				end #run_1010 getdata block
			end #run_1010 query block
			
			attempts += 1
			return nil if not should_retry
			print "Retrying(#{attempts})..."
		end # while loop
		
		return nil # This happens only if the code failed after MAX_RETRIES
	end #run_query
	
	# Clear 1010's cache
	def clear_cache
		print "Clearing cache..."
		url = get_url("clear", @uid, @password, @sid)
		run_1010(url, "") { puts "done" }
	end
	
########################## PRIVATE ############################
private

	def run_1010(url, body = "", xml_params = {})
		begin
			resp = post_query(url, body)
			
			if resp.code != "200"
				handle_network_error( resp )
			else
				xml = wrap_xml(resp.body)						
				xml_params = { 'ForceArray' => false }.merge(xml_params)
				json = XmlSimple.xml_in( xml, xml_params )
				
				if json['rc'] != '0' # 1010 error response
					return handle_1010_error(json['rc'], json['msg'])
				else
					yield(json, xml) if block_given?
				end
			end
		rescue Exception => e
			puts "Exception while running query: #{e}"
			return true
		end
	end
	
	def post_query(url, body = "")
		headers = {	"Content-Type" => "text/xml" }
		uri = URI.parse(url)
		
		http = Net::HTTP::Proxy(PROXY.host, PROXY.port).new(uri.host, uri.port)
		response = http.request_post(uri.request_uri, body, headers)
		return response
	end
	
	def get_data_1010_query(json, options)
		# Columns
		columns = json['table']['cols']['th']
		body = "<cols>\n"
		columns.each { |col| body += "<col>#{col['name']}</col>\n" }
		body += "</cols>\n"

		# Number of rows to retrieve
		numRows = options[:nrows] || json['nrows']
		body += "<rows mode='1'>\n";	# Relative selection, next N rows
		body += "<next>" + numRows + "</next>\n";
		body += "</rows>\n";
		
		# Format
		body += "<format type='xml'>\n";
		# body += "<sep>,</sep>\n";	# for CSV format
		body += "</format>\n";
		
		return body
	end
	
	def wrap_xml(xml)		
		return "<#{WRAP_1010_TAG}>" + xml + "</#{WRAP_1010_TAG}>"
	end
	
	def handle_network_error(resp, message = "Network/IO error")
		puts message
		puts "Error code: #{resp.code}, #{resp.code_type}"
		puts #{resp.body}
		return true	# Retry, since the network error might go away
	end
	
	def handle_1010_error(rc, msg)
		puts "1010 Error, code: #{rc}"
		puts msg
		return false # Since there's probably something wrong with the code, no point in retrying
	end
end

if $0 == __FILE__
	USERNAME = ''
	PASSWORD = ''
	api = API1010.new(USERNAME, PASSWORD)
	
	api.login
	json = api.run_query( { 
		:file => '../code1010/lp-data-avail.xml',
		:table => 'pub.fin.lp.deep2',
		:outfile => '../output/lp-data-avail.csv' 
		} )
		
	api.clear_cache
end
