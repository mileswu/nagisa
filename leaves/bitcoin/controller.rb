# Controller for the Bitcoin leaf.

require 'open-uri'
require 'json'

class Controller < Autumn::Leaf
  
  # Typing "!about" displays some basic information about this leaf.
	def btc_command(stem, sender, reply_to, msg)
		j = JSON.parse(open("https://www.bitstamp.net/api/ticker/").string)
		return "1BTC = $#{j["last"]}"
	end

	def ltc_command(stem, sender, reply_to, msg)
		j = JSON.parse(open("https://btc-e.com/api/2/ltc_usd/ticker").string)
		return "1LTC = $#{j["ticker"]["last"]}"
	end
  
end
