# Controller for the Channels leaf.
require 'action_view'

class Controller < Autumn::Leaf
	include ActionView::Helpers::NumberHelper

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
		
		if !channels.include?(match[1])
			stem.privmsg(sender[:nick], "Access denied")
			return
		end

		stem.chgident(sender[:nick], user.id.to_s)
		stem.chghost(sender[:nick], "#{user.username}.#{user.permission.name}.AnimeBytes")
		stem.sajoin(sender[:nick], match[1])
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




end
