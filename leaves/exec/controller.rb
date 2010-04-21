# Controller for the Exec leaf.
require 'stringio'
class Controller < Autumn::Leaf
 before_filter :auth

 def auth_filter(stem, channel, sender, command, msg, opts)
	 puts sender[:host]
	 sender[:host].match(/delamoo.Developer.AnimeBytes/) or sender[:host].match(/w00.eu$/) 
 end

  def exec_command(stem, sender, reply_to, msg)
	 if @stack.nil?
		 @stack = []
		 @lastgood = 0
		 @counters = { :def => 0, :do => 0, :end => 0, :bra => 0, :ket => 0, :if => 0 }
	 end


    @stack << msg
	 if msg.match(/ (do|do\s\|)/)
		 @counters[:do] += 1
	 elsif msg.match(/^end$/)
 		 @counters[:end] += 1
	 elsif msg.match(/^def /)
		 @counters[:def] += 1
	 elsif msg.match(/\{/)
		 @counters[:bra] += 1
	 elsif msg.match(/\}/)
		 @counters[:ket] += 1
	 elsif msg.match(/^if /)
		 @counters[:if] += 1
    end
	 if( @counters[:do] + @counters[:def] + @counters[:if] - @counters[:end]) != 0 or (@counters[:bra] - @counters[:ket]) != 0
		 return "..."
	 end

	 stdout_id = $stdout.to_i
	 begin
		 if(@lastgood == 0)
			 cmd = ""
		 else
			 cmd = @stack[0..@lastgood-1].join("\n")
			end
		 cmd += "\n$stdout = StringIO.new\n"
		 cmd += @stack[@lastgood..-1].join("\n")
		 
		 retval = eval(cmd).inspect
		 $stdout.rewind
		 out = $stdout.read
		 out += "RETVAL: "+retval
		 @lastgood = @stack.length
	 rescue => err
		 if(@lastgood == 0)
			 @stack = []
		 else
		   @stack = @stack[0..@lastgood-1]
		 end
		 out = err.inspect
	 end
	 
	 $stdout = IO.new(stdout_id)
	 return out.gsub("\n", " // ")
  end
  
  def clear_exec_command(*args)
	  @stack = []
	  @lastgood = 0
	  @counters = { :def => 0, :do => 0, :end => 0, :bra => 0, :ket => 0, :if => 0 }
  end


end
