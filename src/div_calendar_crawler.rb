require 'json'
require_relative 'u.rb'

class Div_calendar_crawler
        COMPANY_NAME = 'COMPANY_NAME'
        SYMBOL = 'SYMBOL'
        EX_DATE = 'EX_DATE'
        DIVIDEND = 'DIVIDEND'
        INDICATED_ANNUAL_DIVIDEND = 'INDICATED_ANNUAL_DIVIDEND'
        RECORD_DATE = 'RECORD_DATE'
        ANNOUNCMENT_DATE = 'ANNOUNCMENT_DATE'
        PAYMENT_DATE = 'PAYMENT_DATE'
        
        def initialize()
	end
	class << self
                attr_accessor :date_range_start
                attr_accessor :date_range_length
                attr_accessor :dry_mode
                attr_accessor :output_directory
                
                def close_output_f(f)
                        if Div_calendar_crawler.output_directory
                                f.close # otherwise f == STDOUT, and we'll leave it alone
                        end
                end
                def crawl_date(date)
                        url = "https://www.nasdaq.com/dividend-stocks/dividend-calendar.aspx?date=#{nasdaq_date(date)}"
                        if !Div_calendar_crawler.dry_mode
                                lines = http_get_lines(url, date)
                                j = 0
                                h = Hash.new
                                first_hit = true
                                f = open_output_f(date)
                                while j < lines.length
                                        if lines[j] =~ %r,<td><a href="https://www.nasdaq.com/symbol/(\w+)/dividend-history">([^&;#<>]*),
                                                h[COMPANY_NAME] = $2                   
                                                h[SYMBOL] = $1.upcase                                         ; j += 1
                                                h[EX_DATE] = extract_datum(lines[j])                          ; j += 1
                                                h[DIVIDEND] = extract_datum(lines[j])                         ; j += 1
                                                h[INDICATED_ANNUAL_DIVIDEND] = extract_datum(lines[j]); j += 1
                                                h[RECORD_DATE] = extract_datum(lines[j])                      ; j += 1
                                                h[ANNOUNCMENT_DATE] = extract_datum(lines[j])                 ; j += 1
                                                h[PAYMENT_DATE] = extract_datum(lines[j])                     ; j += 1
                                                if first_hit
                                                        first_hit = false
                                                else
                                                        f.puts ","
                                                end
                                                f.print(h.to_json)
                                        end
                                        j += 1
                                end
                                close_output_f(f)
                        end
                end
                def crawl()
                        if Div_calendar_crawler.output_directory
                                if !Dir.exist?(Div_calendar_crawler.output_directory)
                                        raise "cannot find directory #{Div_calendar_crawler.output_directory}"
                                end
                        end
                        d = Div_calendar_crawler.date_range_start
                        0.upto(Div_calendar_crawler.date_range_length - 1) do |day_idx|
                                crawl_date(d)
                                d += (24 * 60 * 60)
                        end
                end
                def extract_datum(line)
                        if line =~ %r,<td.*?>(.*?)</td>,
                                $1
                        else
                                raise "could not find data in #{line}"
                        end
                end
                def http_get_lines(url, date)
                        cache_fn = "../http_cache/#{date.strftime("dividends-%Y-%m-%d")}"
                        if !File.exist?(cache_fn)
                                puts "fetching #{url}..."
                                z = U.rest_get(url)
                                File.open(cache_fn, "w") {|f| f.write(z) }
                        else
                                puts "reading cached #{url} at #{cache_fn}..."
                        end
                        IO.readlines(cache_fn)
                end
                def nasdaq_date(d)
                        d.strftime("%Y-%b-%d")
                end
                def open_output_f(date)
                        if !Div_calendar_crawler.output_directory
                                STDOUT
                        else
                                out_fn = "#{Div_calendar_crawler.output_directory}/#{date.strftime("dividends-%Y-%m-%d.json")}"
                                puts "writing #{out_fn}..."
                                File.open(out_fn, "w")
                        end
                end
        end
end
j = 0
Div_calendar_crawler.date_range_start = Time.new
#puts "Div_calendar_crawler.date_range_start=#{Div_calendar_crawler.date_range_start} for #{Div_calendar_crawler.date_range_length}"

Div_calendar_crawler.date_range_start = Time.parse("2018-Oct-17")
Div_calendar_crawler.date_range_length = 1
while ARGV.size > j do
        arg = ARGV[j]
        case arg
        when "-dry"
                Div_calendar_crawler.dry_mode = true
        when "-for"
                j += 1
                Div_calendar_crawler.date_range_length = ARGV[j].to_i
        when "-out"
                j += 1
                Div_calendar_crawler.output_directory = ARGV[j]
        when "-start-on"
                j += 1
                Div_calendar_crawler.date_range_start = Time.parse(ARGV[j])
        when "-year"
                j += 1
                year = ARGV[j].to_i
                Div_calendar_crawler.date_range_start = Time.parse("#{year}-Jan-01")
                Div_calendar_crawler.date_range_length = 365
        else
                raise "did not understand \"#{ARGV[j]}\""
                break
        end
        j += 1
end
#puts "will fetch dividend info starting on #{Div_calendar_crawler.date_range_start}, going on for #{Div_calendar_crawler.date_range_length} day(s)"
Div_calendar_crawler.crawl()
#
#
#
# ruby -wS div_calendar_crawler.rb -out ../out -year 2018
#
#
