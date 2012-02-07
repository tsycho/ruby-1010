require 'sinatra'
require 'erb'
require 'fuzzy_match'

# Initialize
DATA = File.read('../data/deal_coverage.txt').split("\n").map { |row| row.split("\t") };
raise "Invalid data" if (DATA.map { |d| d.size }.max) != (DATA.map { |d| d.size }.min)
DEALS_MAP = {}
all_deals = []
DATA[1..-1].each { |row| 
	deal_name = row[0]
	deal = DEALS_MAP[deal_name]	
	data = { :name => deal_name, :deal_no => row[1], :intex_group => row[2], :pool_id => row[3] } 
	
	if deal.nil?
		DEALS_MAP[deal_name] = [ data ]
		all_deals.push( deal_name )
	else
		deal.push( data )
	end
}
matcher = FuzzyMatch.new(all_deals)

get '/' do
	erb :index
end

get '/deal' do
	bb_name = params["bloomberg_name"]	
	exact_match = DEALS_MAP[bb_name]
	# puts "Found exact match: #{exact_match.inspect}"
	fuzzy_match = DEALS_MAP[matcher.find(bb_name)]
	# puts "Found fuzzy match: #{fuzzy_match.inspect}"

	return "#{bb_name} not found!" if exact_match.nil? && fuzzy_match.nil?
	erb :deal, :locals => { bb_name: bb_name, exact_match: exact_match, fuzzy_match: fuzzy_match }	
end

