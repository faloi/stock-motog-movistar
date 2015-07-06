# This is a template for a Ruby scraper on morph.io (https://morph.io)
# including some code snippets below that you should find helpful

require 'scraperwiki'
require 'mechanize'
require 'gmail'

class MovistarWebScraper
  def initialize
    @agent = Mechanize.new
  end

  def check_stock
    page = agent.get('http://www.tiendamovistar.com.ar/product/MOTO-G-4G-LTE,3195,245.aspx')
    buy_button = page.at('input[name="ctl00$MainContent$ProductInfo1$ctl02$btnBuyPlan"]')

    {timestamp: DateTime.now, has_stock: buy_button['disabled'] != 'disabled'}
  end
end

class MorphNotifier
  def notify(result)
    ScraperWiki.save_sqlite(['timestamp'], result)
  end
end

class GmailNotifier
  def notify(result)
    Gmail.new(username, password) do |gmail|
      send_mail gmail, result
    end
  end

  def send_mail(gmail, result)
    gmail.deliver do
      to "email@example.com"
      subject "Having fun in Puerto Rico!"
      text_part do
        body "Text of plaintext message."
      end
    end
  end
end

result = MovistarWebScraper.new.check_stock
config = {from: ENV['MORPH_MAIL_FROM'], to: ENV['MORPH_MAIL_TO'], password: ENV['MORPH_PASSWORD']}

[MorphNotifier.new, GmailNotifier.new config].do |notifier|
  notifier.notify result
end
