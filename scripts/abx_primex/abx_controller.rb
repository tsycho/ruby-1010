require './abx-extract-from-markit.rb'
require './access_db.rb'
require 'win32ole'

def run
	abx_data_arr = extract_abx_prices(false)

	save_abx_prices_file(abx_data_arr)
	upload_to_access(abx_data_arr)
	save_abx_update_file(abx_data_arr)
end

# Save ABX prices into file (for updating the ABX time series file)
def save_abx_prices_file(abx_data_arr)
	print "Printing ABX prices file..."
	file = File.open("G:/Abs-Re/2011/ABX/daily/Daily ABX update/ABXPrices.csv", 'w')
	file.write("Date,Index,Tranche,Price,Factor,Coupon,RedID\n")

	abx_data_arr.sort.each { |pd| file.write(pd.to_s + "\n") }
	file.close
	puts "Written to file"
end

# Save ABX prices, factors into Access db
def upload_to_access(abx_data_arr)
	puts "Uploading to Access db"

	# Open database connection to insert rows
	db = AccessDb.new('G:\ABSData\CDO-ABS Issuance - Research.mdb')
	db.open
	
	abx_data_arr.sort.each do |pd| 
		sql = "INSERT INTO Spreads_ABX([Date], Series, Rating, ClosingPrice, Factor) " +
			  "VALUES(##{pd.date}#, '#{pd.index}', '#{pd.tranche}', #{pd.price}, #{pd.factor} );"
		db.execute(sql) 
	end
	
	db.close	    
	puts "Written to database"
end

# Write to ABX Update	file (for upload to Dataquery)
def save_abx_update_file(abx_data_arr)
	puts "Updating ABX update file..."	

	datestr = abx_data_arr[0].date
	data_update = [datestr] + abx_data_arr.sort_by { |pdata| "#{pdata.index}-#{pdata.tranche}" }.map { |pd| pd.price }
	
	excel = WIN32OLE.new('Excel.Application');
	workbook = excel.Workbooks.Open('G:\ABS-Re\2011\ABX\daily\Daily ABX update\ABX Update.xls');
	
	worksheet = workbook.Worksheets(1)
	worksheet.Range("A2:Y2").value = data_update
	
	workbook.saved = true
	workbook.Save
	workbook.Close(0)
	excel.Quit
	
	puts "done."	
end

# Main
run()