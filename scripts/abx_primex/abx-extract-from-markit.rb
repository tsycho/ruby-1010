#!C:\Installs\Ruby\bin\ruby.exe

require 'open-uri'
require 'sanitize'
require 'Date'
require 'FileUtils'

# Read url and remove HTML tags, leaving only the text
def read_url
  proxy_addr = 'http://proxy.jpmchase.net:'
  proxy_port = 8443
  url = "http://sf.markit.com/abx.jsp"
  
  page = open(url, :proxy => (proxy_addr + proxy_port.to_s)) 
  html = page.read()
  return Sanitize.clean(html)   
end

class ABXData
  @@tranches = %w(PENAAA AAA AA A BBB BBB-)
  attr_accessor :index, :tranche, :price, :factor, :coupon, :red_id, :date
  
  def initialize(date, index, tranche, price, factor, coupon, red_id)
    @date, @index, @tranche, @price, @factor, @coupon, @red_id = date, index, tranche, price, factor, coupon, red_id
  end

  def <=>(p)
    cmp = @index <=> p.index
    return cmp unless cmp == 0
    return @@tranches.index(@tranche) <=> @@tranches.index(p.tranche) 
  end
 
  def to_s
    return @date + "," + @index + "," + @tranche + "," + @price + "," + @factor + "," + @coupon + "," + @red_id
  end
end

def extract_abx_prices(override)
  data_arr = []
  
  begin
    print "Reading web page..."
    text = read_url
    puts "done"
    
    date = text.scan(/[\w\d\-]+ OverviewIndex/)[0].split(/\s+/)[0]
    date = Date.strptime(date, "%d-%B-%y")    
    puts "Found data for #{date}"
	
    if(override or date == Date.today)
	  datestr = date.strftime("%m/%d/%Y")
	
      # Parse the ABX pricing data
      abxline = text.scan(/ABX.*/)[1]
      abxline.split(/ABX\.HE\./).each { |e|
        if not e.eql? ''
          data = e.strip.split(/\s+/)
          tranche, index = data[0].split(/\./)
		  pd = ABXData.new(datestr, '20' + index, tranche, data[5], data[8], data[3], data[4])
          data_arr.push(pd)
        end
      }
    else  # Sleep for 5 minutes if today's data not available, and retry    
      puts "Data not updated....will retry in 2 mins"
      Kernel::sleep 120
    end
  end while (date != Date.today and not override)

  return data_arr # Array of ABXData objects
end

