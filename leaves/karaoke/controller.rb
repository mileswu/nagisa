# encoding: UTF-8

# Controller for the Karaoke leaf.
require 'open-uri'
require 'hpricot'
require 'net/http'
require 'uri'

class Controller < Autumn::Leaf
	@@active = {}
  
  # Typing "!about" displays some basic information about this leaf.

  def rainbowize(s)
        c=-1;"\2"+s.gsub(/./){|i|c=(c+1)%12;sprintf("\3%02d",c)+i}
  end

  def karaoke_stop_command(stem, sender, reply_to, msg)
	  puts @@active.inspect
	  @@active.delete(reply_to)
  end

  def karaoke_start_command(stem, sender, reply_to, msg)
	  return if @@active[reply_to]
	  @@active[reply_to] = true

	  g = open(msg) { |f| Hpricot(f) } 
	  lrc = g.search("td.code pre").inner_text

	  #IRC delay
	  offset = 300

	  timecodes = []
	  for i in lrc.split("\n")
		  r = i.match(/\[(\d+):(\d\d.\d\d)\]([^\s]+)/)
		  r2 = i.match(/\[offset:(\d+)\]/)
		  if r and r[1] and r[2] and r[3]
			  time = r[1].to_i*60 + r[2].to_f
			  l = r[3] #.force_encoding("UTF-8")

			  timecodes << {:time => time, :line => l}
1		  elsif r2 and r2[1]
			  offset += r2[1].to_f #+ve means up
		  end
	  end
	  if offset
		  timecodes.each { |a| a[:time] -= offset/1000 }
	  end
	  timecodes.delete_if { |a| a[:time] < 0 }

	  to_translate = []
	  regex = Regexp.new('\p{^ASCII}', 'i', 'utf8')
	  timecodes.each_with_index do |i,j|
		  if regex.match(i[:line])
			  to_translate << {:index => j, :line => i[:line] }
		  end
	  end
	  res = Net::HTTP.post_form(URI.parse("http://nihongo.j-talk.com/kanji/"), {"kanji" => to_translate.map{|a|a[:line]}.join("\n"), "conversion"=>"spaced"})
	  h = Hpricot(res.body)
	  counter = 0
	  line = ""
	  new = []
	  list = h.search("#parsewrap").first.containers.each do |i|
		  if i.attributes['class'] == "romaji"
			  line << i.inner_text
		  elsif i.attributes['class'] == "space"
			  line << " "
		  elsif i.name == "br"
			  new << {:time => timecodes[to_translate[counter][:index]][:time], :line=> line}
			  line = ""
			  counter += 1
		  end
	  end
	  timecodes = (new + timecodes).sort { |a,b| a[:time] <=> b[:time] }
	  puts timecodes.inspect
	  
	  
	  stem.privmsg "#{reply_to} Starting karaoke in 5 seconds..."
	  sleep 5
	  stem.privmsg "#{reply_to} GO!"

	  color = ["09", "12"]
	  (timecodes.length).times do |i|
		  return if @@active[reply_to].nil?

		  if i == 0
			  sleep timecodes[0][:time]
		  end
		  stem.privmsg "#{reply_to} \003#{color[i%2]}#{timecodes[i][:line]}"
		  if i != (timecodes.length - 1)
			  sleep (timecodes[i+1][:time] - timecodes[i][:time])
		  end
	  end
	  
	  stem.privmsg "#{reply_to} *Applause*"
	  @@active.delete(reply_to)
	  return
  end
end


