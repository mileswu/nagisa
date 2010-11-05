# Controller for the Control leaf.

class Controller < Autumn::Leaf
	require 'config'
  def commands_command(stem, sender, reply_to, msg)
  end

  def invite9001_command(stem, sender, reply_to, msg)
    stem.invite(msg, "#animebyt.es")
  end
 
  def nick_command(stem, sender, reply_to, msg)
    stem.change_nick(msg) if msg   
  end

  def msg_command(stem, sender, reply_to, msg)
   stem.privmsg msg
  end
 
  # Typing "!about" displays some basic information about this leaf.
  def satsuki_command(stem, sender, reply_to, msg)
          puts "hi"
          stem.privmsg "Satsuki enter #Animebyt.es delamoo #{SATSUKI_PASS}"
  end

  def hello_command(stem, sender, reply_to, msg)
     "Hello world"
  end
  
  def join_command(stem, sender, reply_to, msg)
	  stem.join_channel msg
  end

  def leave_command(stem, sender, reply_to, msg)
         stem.leave_channel msg
  end

  def test_command(stem, sender, reply_to, s)
	c=-1;"\2"+s.gsub(/./){|i|c=(c+1)%12;sprintf("\3%02d",c)+i}
  end

  def test2_command(stem,sender, reply_to,s)
      a=lambda{|i,s|return (s=='' ? s : sprintf("\3%02d%c",i,s[0])+a.call((i+1)%12,s[1..-1]))};"\2"+a.call(0,s)   
  end

  def reload_command(stem, sender, reply_to, msg)
     var :leaves => Hash.new
    if msg then
      if Foliater.instance.leaves.include?(msg) then
        begin
          Foliater.instance.hot_reload Foliater.instance.leaves[msg]
        rescue
          logger.error "Error when reloading #{msg}:"
          logger.error $!
          var(:leaves)[msg] = $!.to_s
        else
          var(:leaves)[msg] = false
        end
        logger.info "#{msg}: Reloaded"
      else
        var :not_found => msg
      end
    else
      Foliater.instance.leaves.each do |name, leaf|
        begin
          Foliater.instance.hot_reload leaf
        rescue
          logger.error "Error when reloading #{name}:"
          logger.error $!
          var(:leaves)[name] = $!.to_s
        else
          var(:leaves)[name] = false
        end
        logger.info "#{name}: Reloaded"
      end
    end

  end

  def about_command(stem, sender, reply_to, msg)
     "delamoo's bot - Running on Autumn (Ruby and GIT)"
  end 
end
