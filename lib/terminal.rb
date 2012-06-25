
class Terminal
  def initialize par
    @peer = par
    while inp = STDIN.gets
      begin
	a_inp = inp.split
	if a_inp[0] == '*' #broadcast?
	  if a_inp[1] == '&file'
	    @peer.broadcast_archivo a_inp[2]
	  else
	    @peer.broadcast_texto inp[2,inp.length]
	  end
	elsif /^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$/.match a_inp[0] #la primer palabra se parece a una ip?
	  ip = a_inp[0]
	  if a_inp[1] == '&file'
	    @peer.enviar_archivo ip, a_inp[2]
	  else
	    @peer.enviar_texto ip, inp[ip.length+1, inp.length]
	  end
	else
	  puts "<Comando Incorrecto>\n"
	end
      rescue Exception => e
	puts "<#{e}>\n"
      end
    end
  end
end

