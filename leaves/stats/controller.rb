# Controller for the Stats leaf.
require 'net/http'
require 'config'
require 'json'
require 'uri'

class Controller < Autumn::Leaf
	def initialize(*args)
		super

		@stats = {}
		Thread.abort_on_exception = true
		Thread.new do
			sleep 5
			update_stats
			while 1
				sleep 60
				update_stats
			end
		end
	end

	def irc_rpl_whoreply_response(stem, sender, recipient, args, msg)
		return if stem.channel_members["#animebyt.es"][args[4]].nil? or args[2]["AnimeBytes"].nil?
		update_state(args[1])
	end

=begin
	def irc_rpl_endofnames_repsonse(stem, sender, recipient, arguments, msg)
		#Does not work whaaaaay
		puts "hi"
		puts arguments.inspect
		puts channel_members["#animebyt.es"].map { |i,j| i }.join(" ")
	end
	
	def did_start_up
		stems.each do |s|
			puts s.inspect
			s.add_listener self
		end
	end
=end

	def someone_did_join_channel(stem, sender, channel)
		if(sender[:nick] == "Nagisa")
			return if channel != "#animebyt.es"
			puts "Just joined a room. ZZZzz"
			sleep 2
			channel_members["#animebyt.es"].each_key do |i|
				stem.who(i)
			end
			return
		end
		
		uid = filter(sender, channel)
		update_state(uid, :join) if uid
	end
	def someone_did_leave_channel(stem, sender, channel)
		uid = filter(sender, channel)
		update_state(uid, :leave) if uid
	end
	def someone_did_quit(stem, sender, msg)
		uid = filter(sender, "#animebyt.es")
		update_state(uid, :leave) if uid
	end

	private

	def filter(sender, channel)
		return false if channel != "#animebyt.es"
		if(sender[:host]["AnimeBytes"].nil?)
			puts "Not identified to Nagisa"
			return false
		end
		return sender[:user]
	end

	def update_state(uid, event = :join)
		puts "#{uid} #{event}"
		if event == :join
			@stats[uid] = { :entered => Time.now.to_i, :left => nil }
		else
			return if @stats[uid].nil?
			@stats[uid][:left] = Time.now.to_i
		end
		Net::HTTP.post_form URI.parse("http://miku.animebyt.es/irc-notifier.php"), {"action" => "status", "uid" => uid, "online" => (event == :join ? "1" : "0"), "auth" => AUTH}
	end

	def update_stats
		t = Time.now.to_i
		out = {}
		@stats.each do |k,h|
			if h[:left]
				dt = h[:left] - h[:entered]
				@stats.delete(k)
				puts "delete #{k}"
			else
				dt = t - h[:entered]
				h[:entered] = t
			end	
			out[k] = { "delta_time" => dt }
		end
		puts out.to_json
		Net::HTTP.post_form URI.parse("http://miku.animebyt.es/irc-notifier.php"), { "stats" => out.to_json, "auth" => AUTH, "action" => "stats" }
	end
end
