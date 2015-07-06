require 'scraperwiki'
require 'mechanize'
require 'gmail'
require 'ostruct'

class MovistarWebScraper
  def initialize
    @agent = Mechanize.new
  end

  def check_stock
    page = @agent.get('http://www.tiendamovistar.com.ar/product/MOTO-G-4G-LTE,3195,245.aspx')
    buy_button = page.at('input[name="ctl00$MainContent$ProductInfo1$ctl02$btnBuyPlan"]')

    OpenStruct.new :timestamp => DateTime.now, :has_stock => buy_button['disabled'] != 'disabled'
  end
end

class MorphNotifier
  def notify(result)
    ScraperWiki.save_sqlite [:timestamp], (to_string_hash result)
  end

  def to_string_hash(result)
    Hash[result.to_h.map { |k, v| [k, v.to_s] }]
  end
end

class GmailNotifier
  def initialize(config)
    @config = config
  end

  def notify(result)
    Gmail.connect!(@config.from, @config.password) do |gmail|
      send_mail gmail, result
    end
  end

  def send_mail(gmail, result)
    gmail.deliver do
      to @config.to
      subject (to_subject result)
    end
  end

  def to_subject
    "Stock al #{result.timestamp}: #{result.has_stock ? 'DISPONIBLE!! :D' : 'naranja :('}"
  end
end

result = MovistarWebScraper.new.check_stock
config = OpenStruct.new :from => ENV['MORPH_MAIL_FROM'], :to => ENV['MORPH_MAIL_TO'], :password => ENV['MORPH_PASSWORD']

[MorphNotifier.new, GmailNotifier.new(config)].each do |notifier|
  notifier.notify result
end
