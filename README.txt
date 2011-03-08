== DESCRIPTION

Ruby library to programmatically run 1010 scripts.
1010 scripts are XML files that can be used to query LoanPerformance (US mortgages database), through the interface provided by www.1010data.com



== REQUIREMENTS

You need a valid 1010 account, enabled for API access.
You need to write your own 1010 code.


== HOW TO USE (simple example code)

# Replace USERNAME, PASSWORD with your own credentials
api = API1010.new(USERNAME, PASSWORD)
api.login

# Run your code
api.run_query( { 
		:file => '../code1010/lp-data-avail.xml',	# File containing your 1010 script
		:table => 'pub.fin.lp.deep2',				# 1010 table to start from, default is 'pub.fin.lp.histplus'
		:separator => ','							# Separator for output file, default is ','
		:outfile => '../output/lp-data-avail.csv' 	# Output file
		} )

# (Optional) Clear the cache when done
api.clear_cache


== TODOs
I need to clean up the code base further (this was extracted out of scripts I created at my work), and especially remove my work-specific settings etc.