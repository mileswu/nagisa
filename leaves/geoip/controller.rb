# Controller for the Geoip leaf.
require 'geoip'
require 'resolv'

class Controller < Autumn::Leaf
	@@geo = GeoIP.new("GeoLiteCity.dat")

	def geoip_command(stem, sender, reply_to, msg)
		begin
			r = @@geo.city(msg)
			ip = r[1].split(".")
			
			origin = Resolv::DNS.new.getresource("#{ip[3]}.#{ip[2]}.#{ip[1]}.#{ip[0]}.origin.asn.cymru.com", Resolv::DNS::Resource::IN::TXT).strings.first
			asn = origin.split("|")[0].strip rescue ""
			unless asn == ""
				asn2 = Resolv::DNS.new.getresource("as#{asn}.asn.cymru.com", Resolv::DNS::Resource::IN::TXT).strings.first
				puts asn2
				isp = "-- " + asn2.split("|")[4].lstrip.strip
			end

			return "#{r[1]}: #{r[7]}, #{r[6]}, #{r[4]} #{isp}"
		rescue
			return "Error - sowwy"
		end
	end

	alias_method :geo_command, :geoip_command 
	alias_method :ip_command, :geoip_command 
end
