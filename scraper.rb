require 'scraperwiki'
require 'mechanize'
require 'ostruct'
require 'mandrill'

class MovistarWebScraper
  URL = 'http://www.tiendamovistar.com.ar/product/MOTO-G-4G-LTE,3195,245.aspx'

  def initialize
    @agent = Mechanize.new
  end

  def check_stock
    page = @agent.get URL
    buy_button = page.at 'input[name="ctl00$MainContent$ProductInfo1$ctl02$btnBuyPlan"]'

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
    send_mail (to_subject result), (to_body result)
  end

  def send_mail(subject, body)
    mandrill = Mandrill::API.new @config.mandrill_api_key

    message = {
     :subject => subject,
     :from_name => "Movistar Stock Check",
     :to => [
       {:email => @config.to}
     ],
     :from_email => @config.from
    }

    mandrill.messages.send message
  end

  def to_subject(result)
    "#{result.has_stock ? '¡Ya hay stock de Moto G! :D' : 'Todavia no hay stock de Moto G'} (#{result.timestamp.strftime '%c'})"
  end

  def to_body(result)
    "Compralo en #{MovistarWebScraper::URL}" if result.has_stock
  end
end

result = MovistarWebScraper.new.check_stock
config = OpenStruct.new :from => ENV['MORPH_MAIL_FROM'], :to => ENV['MORPH_MAIL_TO'], :mandrill_api_key => ENV['MORPH_MANDRILL_API_KEY']

[MorphNotifier.new, GmailNotifier.new(config)].each do |notifier|
  notifier.notify result
end
