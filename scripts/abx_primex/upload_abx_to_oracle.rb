require './abx-extract-from-markit.rb'
require 'oci8'

def run
	abx_data_arr = extract_abx_prices(true)
	upload_to_oracle(abx_data_arr)
end

def upload_to_oracle(abx_data_arr)
	db = OCI8.new('mbsapps', 'mbsapps', 'mbsdb')
	
	abx_data_arr.each do |pd| 

		datestr = "#{pd.date[-4..-1]}#{pd.date[0...2]}#{pd.date[3...5]}"
		index_name = "ABX.HE.#{pd.index[2..-1]}.#{pd.tranche}"
	
		if (pd.tranche =~ /AAA/).nil?	# Non AAA
#			sql = "insert into daily.non_agy_pricing_indices(INDEX_NAME, CCYYMMDD, PRICE, FACTOR, COUPON, RED_ID, MODEL) " + 
#				"values('#{index_name}', #{datestr}, #{pd.price}, #{pd.factor}, #{pd.coupon}, '#{pd.red_id}', '0')"
			sql = "insert into daily.non_agy_pricing_indices(INDEX_NAME, CCYYMMDD, PRICE, FACTOR, RED_ID, MODEL) " + 
				"values('#{index_name}', #{datestr}, #{pd.price}, #{pd.factor}, '#{pd.red_id}', '0')"
		else
#			sql = "update daily.non_agy_pricing_indices " + 
#				"set COUPON=#{pd.coupon}, RED_ID='#{pd.red_id}', PRICE=#{pd.price}, FACTOR=#{pd.factor} " +
#				"where CCYYMMDD=#{datestr} and INDEX_NAME='#{index_name}'"
			sql = "update daily.non_agy_pricing_indices " + 
				"set RED_ID='#{pd.red_id}', PRICE=#{pd.price}, FACTOR=#{pd.factor} " +
				"where CCYYMMDD=#{datestr} and INDEX_NAME='#{index_name}'"
		end
		
		db.exec(sql) 
	end
	
	db.commit
end

# Main
run()
