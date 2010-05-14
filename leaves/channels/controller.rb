# Controller for the Channels leaf.
require 'action_view'
require 'config'

class Controller < Autumn::Leaf
	include ActionView::Helpers::NumberHelper
	def did_start_up
		s = stems.to_a.first
		s.oper "Satsuki", OPER_PASS
		s.chgident("Satsuki", "Satsuki")
		s.chghost("Satsuki", "bakus.dungeon")

		Channel.all.map { |c| c.channel }.each do |c|
			s.sajoin "Satsuki", c
		end
	end


	def did_receive_private_message(stem, sender, msg)
		match = msg.match(/enter (.+) (.+) (.+)/i) #enter <channel> <user> <pass>
		return if match.nil?

		user = User.first(:username => match[2].downcase, :enabled => "1")
		if user.nil?
			stem.privmsg(sender[:nick], "Invalid username")
			return
		elsif user.irc_key != match[3]
			stem.privmsg(sender[:nick], "Invalid irckey")
			return
		end

		channels = Channel.all(:level.lte => user.permission.level).map { |c| c.channel } 
		
		if !channels.include?(match[1].downcase)
			stem.privmsg(sender[:nick], "Access denied")
			return
		end

		stem.chgident(sender[:nick], user.id.to_s)
		stem.chghost(sender[:nick], "#{user.username}.#{user.permission.name.gsub(" ", "")}.AnimeBytes")
		stem.sajoin(sender[:nick], match[1].downcase)
	end

	def user_command(stem, sender, reply_to, msg)
		if msg.nil?
			user = User.get(sender[:user])
		else
			user = User.first(:username => msg)
		end
		return "User not found" if user.nil?

		if user.paranoia < 4
			ratio = (user.ratio.nan? ? "Inf." : "%.1f" % user.ratio)
			stats = "Up: #{number_to_human_size(user.uploaded)}, Down: #{number_to_human_size(user.downloaded)}, Ratio: #{ratio} :: "
		else
			stats = ""
		end
		return "#{user.username} :: #{stats}http://animebyt.es/user.php?id=#{user.id} || https://yuki.animebyt.es/user.php?id=#{user.id}"
	end


	def search_command(stem, sender, reply_to, msg)
		return if msg.nil?


		r = AnimeGroup.search_first("@SeriesNames #{msg}")
		return "Nothing found" if r.nil?
		tag_arr =  r.animetags.map {|t| t.name }
		tag_arr.delete("")
		tags = tag_arr.join(", ")

		"#{r.series.name} - #{r.name} [#{r.year}] :: Tags: #{tags} :: http://animebyt.es/torrents.php?id=#{r.id} || https://yuki.animebyt.es/torrents.php?id=#{r.id}"
	end


end
