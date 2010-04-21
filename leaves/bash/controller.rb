# Controller for the Bash leaf.

require 'open-uri'
require 'hpricot'
class Controller < Autumn::Leaf
  
  
  def bash_command(stem, sender, reply_to, msg)

flag = 1
while flag == 1
  flag = 0
  h = Hpricot(open("http://bash.org/?random"))
  tables = h.search("table")
  if tables and tables[2]
    tr = tables.search("tr")
    quotes = []
    if tr and tr[0]
       chunk = tr[0]
       qtinfos = tr.search("p.quote")
       qts = tr.search("p.qt")
       qtinfos.count.times do |i|
			 id = qtinfos[i].search("b")[0].inner_text[1..-1].to_i if qtinfos[i].search("b")
          votes = qtinfos[i].inner_text.scan(/\(.*\)/)
          if votes and votes[0]
            n = votes[0][1..-2].to_i
            txt = qts[i].inner_text
            next if txt.length > 500
            next if n < 1000
            quotes << {:text => txt.gsub("\n", " // ").gsub("\r",""), :votes => n, :id =>id}
          end
       end
    end
  end
  flag = 1 if quotes.count == 0
end


quotes.sort! { |a,b| a[:votes] <=> b[:votes] }.reverse!

"Bash QDB :: http://bash.org/?#{quotes[0][:id]} :: " + quotes[0][:text]

  end
end
