# Controller for the RSS leaf.
require 'open-uri'
require 'hpricot'
require 'config'

class Controller < Autumn::Leaf
	def initialize(*args)
		super

		@done = []
		Thread.new do 
			sleep 10
			get_rss('first')
			while 1
				get_rss
				sleep 5
			end
		end
	end

	def get_rss(mode = false)
		begin
			doc = open(RSS_FEED) { |f| Hpricot(f) }
		rescue Exception
			puts "HTTP failed"
			if(mode == 'first')
				sleep 10
				puts "Retrying"
				get_rss(mode)
			end
			return		
		end

		doc.search("item") do |e|
			hsh = e.at("title").inner_text + e.at("pubdate").inner_text
			if(!@done.include?(hsh))
				@done << hsh
				url = e.at("comments").inner_text
				text = e.at("title").inner_text + " || " + url + " || " + url.sub("http://", "https://yuki.")
				if mode == false
					stems.each do |s|
						s.privmsg("#announce", text) if s.server == "irc.animebyt.es"
					end
				end
			end
		end
	end

end
