require 'nokogiri'
require 'open-uri'
require 'pp'

DOMAIN = "http://www.babynames.ch"

index = Nokogiri::HTML(open("#{DOMAIN}/Info/SeriesList"));

class NameList
  attr_accessor :year, :root, :gender, :names, :country
  def initialize(y, r, c)
    self.year = y 
    self.root = r 
    self.gender = r[-1,1] 
    self.country = c 
  end

  def get_names
    return if(self.gender == 'f')
    index = Nokogiri::HTML(open("#{DOMAIN}#{self.root}"));
    self.names = index.css(".basicTable a.fna, .basicTable a.mna").map { |node| node.text.strip } 
  end

  def filename
    "#{self.country.name}_#{self.year}_#{self.gender}.txt".gsub(/[^0-9A-z.\-]/, '_')
  end
end

class Country
  attr_accessor :name, :root, :lists
  def initialize(n, r)
    self.name = n 
    self.root = r 
  end

  def get_lists
    index = Nokogiri::HTML(open("#{DOMAIN}#{self.root}"));
    self.lists = index.css(".infoTable a.to").map { |node| NameList.new(node.text.strip, node["href"], self) }
  end
end

countries = index.css(".basicTable a.to").map { |node| Country.new(node.text.strip, node["href"]) }

countries.each do |c| 
  puts "Processing #{c.name}"
  c.get_lists
  c.lists.each do |l| 
    puts "\tProcessing #{l.year} - #{l.gender}"
    if l.get_names
      File.open(l.filename, 'w') do |f| 
        l.names.each { |n| f.puts n } 
      end
    end
  end
end
