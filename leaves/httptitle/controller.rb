# Controller for the test leaf.
require 'uri'
require 'curb'
require 'zlib'
require 'cgi'
require 'hpricot'
require 'escape'
require 'htmlentities'
require 'idn'

class Controller < Autumn::Leaf

  def irc_privmsg_event(stem, sender, args)
	  return if(args[:channel].nil?)
	  return if sender[:nick] and (sender[:nick] == "Nanoka" or sender[:nick] == "Satsuki" or sender[:nick] == "Momiji" or sender[:nick] == "godzilla" or sender[:nick] == "Internets")

	  return if youtube(stem, sender, args) #Youtube
	  wasABlink = yuki_convert(stem, sender, args) #HTTP<->HTTPS AB
	  
	  if(!wasABlink)
		title = httptitle(stem, sender, args)
		#screenshot(stem, sender, args, title)
	  end
	  
	  
	  return
  end
  
private

  def screenshot(stem, sender, args, title)
	res = args[:message].match(/(http|https):\/\/[^\s]*/ix)
	return unless (res and res[0])
	url = res[0]
	
	base_path = "/home/mileswu/public_html/ab/irc-html/#{Time.now.to_i.to_s}-#{args[:channel]}-#{sender[:nick]}"

	`webkit2png.py "#{Escape.shell_command([url])}" > #{Escape.shell_command([base_path + "-o.png"])}`
	`convert #{Escape.shell_command([base_path + "-o.png"])} -crop 1024x768+0+0 -trim -quality 50 #{Escape.shell_command([base_path + "-l.jpg"])}`
	`convert #{Escape.shell_command([base_path + "-o.png"])} -crop 1024x768+0+0 -trim -quality 50 -resize 144x115 #{Escape.shell_command([base_path + "-s.jpg"])}`
	
	f = File.open(base_path +".txt", "w")
	f.puts((title.class == String ? title : url))
	f.puts(url)
	f.close
	
	return  
  end

  def isredirect(url)
	return false if url["news.bbc.co.uk"] #BBC NEWS FIX
  
	curb = Curl::Easy.new(url)
	begin
		curb.http_head
		puts curb.response_code
		if(curb.response_code == 301 or curb.response_code == 302)
			return true
		end
	rescue => e
		puts e
	end
	return false
  end
  
  def isidn(url)
	return false

  	res = url.match(/(http|https):\/\/[^\s\/]*/ix)
	res2 = url.match(/(http|https):\/\/[^\s]*/ix)
	if res and res[0]
		urlidn = IDN::Idna.toASCII(res[0])
		return true if urlidn != res[0]
	end
	return false
  end

  def httptitle(stem, sender, args)
	res = args[:message].match(/(http|https):\/\/[^\s]*/ix)
	return unless res and res[0]
	url = res[0]

    u = stem.users(args[:channel])
	
	dontprint = false
	dontprint = true if(u.include? "Nanoka" and !isredirect(url) and !isidn(url))

	#Generic HTTP
	res = args[:message].match(/(http|https):\/\/[^\s]*/ix)
	base_res = args[:message].match(/(http|https):\/\/[^\s\/]*/ix)
	if args[:message].include? "https" 
	  proto = "https://"
	else
	  proto = "http://"
	end
	if res and res[0] and base_res and base_res[0]
	 url = res[0]
	 urlidn = IDN::Idna.toASCII(base_res[0][proto.length..-1])
	 #urlidn = base_res[0][proto.length..-1]
	 url = proto + urlidn + url[base_res[0].length..-1]
	 curb = Curl::Easy.new(url)
	 #curb.headers["Accept-Encoding"] = ""
	 curb.follow_location = true
	 begin
		curb.http_head
		len = curb.header_str.match(/Content-Length: [0-9]*\r\n/)
		if len and len[0]
			len = len[0]["Content-Length: ".length..-3].to_i
			if len > 1000000
				curb.headers["Range"] = "bytes=0-1000000"
			end
		end
		curb.http_get
	 rescue => err
		 puts "CURL ERR: #{err}"
		 return
	 end
	 
	 puts "CURL 206" if curb.response_code == 206
	 if curb.response_code != 200 and curb.response_code != 206
		 puts "HTTP #{curb.response_code}"
		 return
	 end

	 if curb.header_str.include? "Content-Encoding: gzip"
		 data = Zlib::GzipReader.new(StringIO.new(curb.body_str)).read
	 else
		 data = curb.body_str
	 end
	 extract = data.match(/<title>.*?<\/title>/ixm)
	 if extract
		 m = extract[0]["<title>".length..-"</title>".length-1].gsub("\t", "").gsub("\n","").gsub("\r","")
		 coder = HTMLEntities.new
		 m = coder.decode(m)
		 stem.privmsg "#{args[:channel]}", "Title -> #{m}" unless dontprint
		 return m
	 end
	end
	return true
  end
  
  def youtube(stem, sender, args)
	res = args[:message].match(/http:\/\/(www.)?youtube.com\/watch\?(.*)v=([^\s]*)/ix)
	if res and res[3]
		video_id = res[3]
		begin
			curb = Curl::Easy.new("http://gdata.youtube.com/feeds/api/videos/" + video_id)
			curb.http_get
			str = curb.body_str

			h = Hpricot(str)

			pos = h.search("yt:statistics")
			view_count = (pos and pos[0] and pos[0]['viewcount']) ? "Views: #{pos[0]['viewcount']}, " : ""

			pos = h.search("yt:duration")
			length = (pos and pos[0] and pos[0]['seconds']) ? "Length: #{pos[0]['seconds'].to_i/60}:#{pos[0]['seconds'].to_i%60}" : ""

			pos = h.search("media:title")
			title = (pos and pos[0]) ? "Title: #{pos[0].inner_text}, ": ""

			m = "#{title}#{view_count}#{length}"
			stem.privmsg args[:channel], m
		rescue => e
			puts "CURL err #{e}"
		end
		return true
	end
	return false
  end
  
  def yuki_convert(stem, sender, args)
	u = stem.users(args[:channel])
  
	res = args[:message].match(/http:\/\/animebyt\.es\/[^\s]*/ix)
	if res and res[0]
	  str = "SSLified: https://yuki.animebyt.es/" + res[0]["http://animebyt.es/".length..-1]
	  stem.privmsg(args[:channel], str) unless u.include? "Nanoka"
	  return true
	end
	res = args[:message].match(/https:\/\/yuki\.animebyt\.es\/[^\s]*/ix)
	if res and res[0]
	  str = "Non-SSL: http://animebyt.es/" + res[0]["https://yuki.animebyt.es/".length..-1]
	  stem.privmsg(args[:channel], str) unless u.include? "Nanoka"
	  return true
	end
	return false
  end

end
