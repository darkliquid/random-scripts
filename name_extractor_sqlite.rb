require 'nokogiri'
require 'open-uri'
require 'pp'

DB = "names.db"
DOMAIN = "http://www.babynames.ch"

require 'active_record'

ActiveRecord::Base.logger = Logger.new(STDERR)

ActiveRecord::Base.establish_connection(
  :adapter => "sqlite3",
  :database  => DB
)

ActiveRecord::Schema.define do
  create_table :names do |t|
    t.column :name, :string, null: false
    t.column :group, :string
    t.column :info, :string
    t.column :gender, :integer, default: 0, null: false
    t.column :usrank, :integer
    t.index :name, unique: true
  end

  create_table :origins do |t|
    t.column :name, :string, null: false
    t.index :name, unique: true
  end

  create_join_table :names, :origins do |t|
    t.index [:name_id, :origin_id], unique: true
  end

  create_table :langs do |t|
    t.column :name, :string, null: false
    t.index :name, unique: true
  end

  create_join_table :names, :langs do |t|
    t.index [:name_id, :lang_id], unique: true
  end
end

class Lang < ActiveRecord::Base
  has_and_belongs_to_many :names
end

class Origin < ActiveRecord::Base
  has_and_belongs_to_many :names
end

class Name < ActiveRecord::Base
  has_and_belongs_to_many :origins
  has_and_belongs_to_many :langs

  def self.parse(arr, gender)
    entry = Name.find_or_create_by(name: arr[0].strip)
    entry.group = arr[1].strip
    arr[2].strip.split(",").map(&:strip).map do |o|
      if !entry.origins.exists?(name: o)
        entry.origins << Origin.find_or_create_by(name: o)
      end
    end
    arr[3].strip.split(",").map(&:strip).map do |l|
      if !entry.langs.exists?(name: l)
        entry.langs << Lang.find_or_create_by(name: l)
      end
    end
    entry.info = arr[4].strip
    entry.usrank = arr[5].strip.gsub(/[^0-9]/,'').to_i
    entry.gender += (gender ? 1 : 2)
    entry.save
    entry
  end
end

def get_names(letter, gender)
  url = "#{DOMAIN}/Info/ExtSearch?StartsWith0=#{letter}"
  if gender
    url += "&Female=False&Male=True"
  else
    url += "&Female=True&Male=False"
  end

  entries = []

  next_page = 1
  while true
    page = Nokogiri::HTML(open(url + "&page=#{next_page}").read)
    page.encoding = 'utf-8'
    page.css(".basicTable tr").each_with_index do |node, idx|
      if idx > 0
        Name.parse(node.css("td").map {|n| n.text.strip }, gender)
      end
    end
    if page.at('.pager a:contains(">")')
      next_page += 1
    else
      break
    end
  end

  return entries
end

('A'..'Z').each do |letter|
  get_names(letter, false)
  get_names(letter, true)
end
