# Controller for the ThreadNecro leaf.
require 'open-uri'
require 'activesupport'

class Controller < Autumn::Leaf
  
  # Typing "!about" displays some basic information about this leaf.
  
  def threadnecro_command(stem, sender, reply_to, msg)
if msg
	match = msg.match(/#(\d+)/)
	if match and match[1]
	 u = match[1].to_i
	else
		u = msg
	end
else
	u = sender[:nick]
end
u = (u == 0 ? msg : u)

arr = open("http://dl.dropbox.com/u/1581546/threadnecro.txt").read.split("\n")
begin
	arr = arr[arr.index(arr.find { |a| a =~ /LEADERBOARD/ })+1..-1]
rescue => e
	puts e
end

#find user
if u.class == String
	if u.length < 3
		s = arr.select { |a| a =~ /(\d+). #{u} -+ (\d+) \((\d+) posts? \/ ([\d.]+) avg ppp/i }
	else
		s = arr.select { |a| a =~ /(\d+). .*#{u}.* -+ (\d+) \((\d+) posts? \/ ([\d.]+) avg ppp/i }
	end
else
	s = arr.select { |a| a =~ /^\s*#{u}. (\w+) -+ (\d+) \((\d+) posts? \/ ([\d.]+) avg ppp/i }
end

if s.empty?
  stem.message "#{u} not found", reply_to
  return
end
for i in s
  matchdata = i.match(/(\d+). (\w+) -+ (\d+) \((\d+) posts? \/ ([\d.]+) avg ppp/)
  if matchdata[1] and matchdata[2] and matchdata[3] and matchdata[4] and matchdata[5]
	m = "#{matchdata[2]}: #{matchdata[1].to_i.ordinalize} with #{matchdata[3]} points (#{matchdata[4]} posts / #{matchdata[5]} ppp)"
	stem.message m, reply_to
  end
end
  return  
  end
end
