# Controller for the Bitcoin leaf.

require 'open-uri'
require 'json'

class Controller < Autumn::Leaf
  
  # Typing "!about" displays some basic information about this leaf.
	def btc_command(stem, sender, reply_to, msg)
		j = JSON.parse(open("https://data.mtgox.com/api/2/BTCUSD/money/ticker").string)
		return "1BTC = #{j["data"]["last_local"]["display_short"]}"
	end
  
end
