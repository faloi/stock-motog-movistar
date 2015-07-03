# This is a template for a Ruby scraper on morph.io (https://morph.io)
# including some code snippets below that you should find helpful

require 'scraperwiki'
require 'mechanize'

agent = Mechanize.new

# Read in a page
page = agent.get('http://www.tiendamovistar.com.ar/product/MOTO-G-4G-LTE,3195,245.aspx')

# Find somehing on the page using css selectors
buy_button = page.at('input[name="ctl00$MainContent$ProductInfo1$ctl02$btnBuyPlan"]')

# Write out to the sqlite database using scraperwiki library
ScraperWiki.save_sqlite(['timestamp'], { 'timestamp' => DateTime.now, 'has_stock' => buy_button['disabled'] != 'disabled' })