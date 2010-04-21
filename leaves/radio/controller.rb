# Controller for the radio leaf.
require 'net/http'
require 'uri'

class Controller < Autumn::Leaf

def radio_command(stem, sender, reply_to, msg)
	shortcuts = {
		"ab" => "http://91.121.115.70:8000/stream",
		"w00" => "http://w00.eu:8000/stream.ogg",
		"animenfo" => "http://216.18.227.252:8000/",
		"kawaii" => "http://server1.kawaii-radio.net:9000/"
	}
	if msg == "" or msg.nil?
		urlstr = shortcuts["ab"]
	else
		urlstr = shortcuts[msg.downcase]
		urlstr = msg if urlstr.nil?
	end
	begin
		url = URI.parse(urlstr)
	rescue
		return "Not a valid URL"
	end
	return "Not a valid URL" if url.class != URI::HTTP

	str = ""
	hsh = {}
	begin
		timeout(5) do
			s = TCPSocket.new(url.host, url.port)
			s.print("GET #{url.path} HTTP/1.1\r\n")
			s.print("Host: #{url.host}\r\n")
			s.print("Accept: */*\r\n")
			s.print("Icy-MetaData:1\r\n")
			s.print("\r\n")
			while 1
				nstr = s.recvfrom(1000)[0]
				str << nstr
				break if str.length > 35000 or nstr.empty?
			end
			s.close
		end
	rescue Timeout::Error
		puts "timeout"
	rescue => err
		puts err
	end
	
	return "Unable to connect to #{urlstr}" if str == ""
	return "Not currently running #{urlstr}" if str["HTTP/1.0 404"] or str["HTTP/1.1 404"]

	if(str["Content-Type: application/ogg"])

		for i in ["ARTIST", "ALBUM", "TITLE"]
				pos = str.match(/(....)#{i}=(.*?)(\n|\t|\00)/i)
				if pos and pos[1] and pos[2]
						l = pos[1].unpack("I*")[0] - i.length - 1
						puts l
						hsh[i] = pos[2][0..(l-1)]
				end
		end
	else
		pos = str.match(/StreamTitle='(.*?)';/i)
		if pos and pos[1]
			hsh["TITLE"] = pos[1]
		end
	end
	if hsh["TITLE"] == ""
		pos = str.match(/icy-name:(.*)/i)
		if pos and pos[1]
			hsh["TITLE"] = pos[1]
		else
			hsh["TITLE"] = nil
		end
	end

	return "An unknown error occured. Perhaps this is not a radio stream or it is mid-way thru changing tracks" if hsh.empty?
	return "Radio #{urlstr} :: #{hsh["TITLE"]}#{" - " if hsh["ARTIST"] and hsh["TITLE"]}#{hsh["ARTIST"]}#{(" (" + hsh["ALBUM"] + ")") if hsh["ALBUM"]}"
end

end
