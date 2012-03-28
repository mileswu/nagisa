# Controller for the Weather leaf.
require 'open-uri'
require 'hpricot'
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

                if msg.nil?
                   if @storage[sender[:nick]]
                       msg = @storage[sender[:nick]]
                   else
                       return "No past location stored."
                   end
                end
                   
		doc = open("http://www.google.com/ig/api?weather=" + CGI::escape(msg)) { |f| Hpricot(f) }
		
		if doc.at('city').nil?
			return "Not found"
		end
		city = doc.at('city')['data']

		@storage[sender[:nick]] = msg
		File.open('weather.yml', 'w') { |out| YAML.dump(@storage, out) }

		s = {}
		s2 = {}
		s[:condition] = doc.at('current_conditions').at('condition')
		s[:f] = doc.at('current_conditions').at('temp_f')
		s[:c] = doc.at('current_conditions').at('temp_c')
		s[:humidity] = doc.at('current_conditions').at('humidity')
		s[:wind] = doc.at('current_conditions').at('wind_condition')
		s.each_pair do |k,i|
			s2[k] = (i ? i['data']: '')
		end
	
		return "#{city}: #{s2[:condition]}, #{s2[:c]}C, #{s2[:wind]}, #{s2[:humidity]}"
		
	end
end
