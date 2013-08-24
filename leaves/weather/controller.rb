# Controller for the Weather leaf.
require 'open-uri'
require 'nokogiri'
require 'cgi'
require 'yaml'

class Controller < Autumn::Leaf

	# Typing "!about" displays some basic information about this leaf.

	def w_command(stem, sender, reply_to, msg)
		if @storage.nil?
			begin
 			  @storage = YAML.load_file('weather.yml')
			rescue
				@storage = {}
			end
		end

                if msg.nil? or msg == ""
                   if @storage[sender[:nick]]
                       msg = @storage[sender[:nick]]
                   else
                       return "No past location stored."
                   end
                end

			doc = Nokogiri::HTML(open("http://where.yahooapis.com/v1/places.q(" + CGI::escape(msg) + ")?appid=_NjDJJ_V34EcKptv9R8wyfOEb7npjCytjQb9b2DZQ1eYbwa2JItdjW85XZt0aw--"))

			if doc.css('woeid').empty?
					return "Not found"
			end
			woeid = doc.css('woeid')[0].content

                   
		@storage[sender[:nick]] = msg
		File.open('weather.yml', 'w') { |out| YAML.dump(@storage, out) }

		doc = Nokogiri::HTML(open("http://weather.yahooapis.com/forecastrss?w=#{woeid}&u=c"))

		city = ''
		if doc.css("title").size > 0
			  city = doc.css("title")[0].content.sub("Yahoo! Weather - ", "")
		end 

		s = {}
		s2 = {}
		if doc.css("condition").size > 0
			  s[:condition] = doc.css("condition")[0]['text']
				  s[:c] = doc.css("condition")[0]['temp']
		end
		if doc.css("atmosphere").size > 0
			  s[:humidity] = doc.css("atmosphere")[0]['humidity']
		end
		if doc.css("wind").size > 0
			  if doc.css('wind')[0]['speed']
					    s[:wind] = doc.css('wind')[0]['speed'].to_f.round()
							  end
		end

		return "#{city}: #{s[:condition]} #{s[:c]}C, #{s[:wind]} km/hr wind, #{s[:humidity]}% humidity"

		
	end
end
