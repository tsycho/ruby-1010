require 'sinatra'
require 'erb'

# Initialize
DATA = File.read('../data/deal_coverage.txt').split("\n").map { |row| row.split("\t") }
raise "Invalid data" if (DATA.map { |d| d.size }.max) != (DATA.map { |d| d.size }.min)
DEALS_MAP = {}
DATA[1..-1].each { |row|
	deal = DEALS_MAP[row[0]]
	data = { :deal_no => row[1], :intex_group => row[2], :pool_id => row[3] } 
	
	if deal.nil?
		DEALS_MAP[row[0]] = [ data ]
	else
		deal.push( data )
	end
}

get '/' do
	erb :index
end

get '/deal' do
	bb_name = params["bloomberg_name"]
	deal_data = DEALS_MAP[bb_name]
	return "#{bb_name} not found!" if DEALS_MAP[bb_name].nil?
	erb :deal, :locals => { :bb_name => bb_name, :deal_data => deal_data }
end

