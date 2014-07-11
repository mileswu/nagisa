# Controller for the Bans leaf.

class Controller < Autumn::Leaf

def initialize(*args)
	super
	@bans = []
end
  
def irc_privmsg_event(stem, sender, args)
	return if(args[:channel] != "#uguu~subs2" and args[:channel] != "#uguu~subs")

	m = args[:message]

	filter = [
		/nantucket/i,
		/op onions/i,
		/NGEN/
	]

	filter.each do |i|
		if m.match(i)
			stem.kick(args[:channel], sender[:nick], "Dame da~")
			return
		end
	end
end
  
end
