require 'rubygems'
require 'open-uri'
require 'nokogiri'

MONTHS_TO_NUM = (1..12).inject({}) { |hash, month| hash[Date.new(2011, month).strftime('%B')] = month; hash }
NUM_TO_MONTHS = MONTHS_TO_NUM.dup.invert
ARCHIVE_URL = 'http://dictionary.reference.com/wordoftheday/archive'

def get_page_following_iframe_if_needed(url)
  html = Nokogiri::HTML(open(url).read)
  redirect = html.search('//iframe[@id="classic_ifrm"]/@src')
  return redirect.empty? ? html : Nokogiri::HTML(open(redirect.first).read)
end

today = Date.today
if ARGV.empty?
  month = today.month
  day = today.day
else
  month = ARGV[0].to_i || today.month
  day = ARGV[1].to_i || today.day
end

words_of_the_day = []

links_for_month = get_page_following_iframe_if_needed(ARCHIVE_URL).search("//table//a[text()='#{NUM_TO_MONTHS[month]}']/@href").map { |l| l.value }
links_for_month.each do |link|
  page = get_page_following_iframe_if_needed(link)
  words_of_the_day << page.search("//div[@id='primary']/ol/li[#{day}]//text()").map { |l| l.to_s }.join
end

puts "All Word of the Days for #{NUM_TO_MONTHS[month]} #{day}"
puts
words_of_the_day.each do |wotd|
  puts wotd
end
