MAX_LARGO_MENSAJE = 255
MAX_LARGO_ARCHIVO = 65535

class Peer

  def initialize puerto
    @puerto = puerto
    @threads = []

    @s_broadcast_salida = UDPSocket.new
    @s_broadcast_salida.setsockopt(Socket::SOL_SOCKET, Socket::SO_BROADCAST, true)

    @s_broadcast = UDPSocket.new
    @s_broadcast.bind '0.0.0.0', puerto
    @threads << Thread.new do
      loop do
	msj, addr = @s_broadcast.recvfrom(MAX_LARGO_ARCHIVO)
	ip = addr[3]
	self.procesar_mensaje ip, msj
      end
    end

    @s_listener = TCPServer.open puerto
    @threads << Thread.new do
      while(sesion = @s_listener.accept)
	@threads << Thread.new(sesion) do |ses|
	  entrada = ses.gets
	  if !entrada.nil?
	    ip = ses.addr[3]
	    self.procesar_mensaje ip, entrada
	  end
	  ses.close
	end
      end
    end
  end

  def procesar_mensaje ip_origen, datos_en_xml
    xml =  Nokogiri::Slop datos_en_xml
    file = xml.message.file if xml.message.children[0].name == 'file'
    texto = xml.message.body.content if xml.message.children[0].name == 'body'

    if file.nil? && texto.nil?
      raise "#{ip_origen} envio un mensaje que no es comprensible"
    else
      if !file.nil?
	nombre_arch = file.attribute('name').value
	arch = File.new("./actual/#{nombre_arch}","w")
	begin
	  arch.write(Base64.urlsafe_decode64 file.content )
	rescue
	  raise "error recibiendo archivo"
	ensure
	  arch.close
	end
	puts "<Recibido ./#{nombre_arch}>\n"
      else
	t = Time.now.to_s.split
	puts "[#{t[0]} #{t[1]}] #{ip_origen} #{texto[0,MAX_LARGO_MENSAJE]}\n"
      end
    end
  end

  def xml_texto texto
    "<message><body>#{texto}</body></message>"
  end

  def xml_archivo arch
    enc_arch = Base64.urlsafe_encode64(arch.read)
    "<message><file name='#{File.basename(arch.path)}'>#{enc_arch}</file></message>"
  end

  def enviar_texto ip, texto
    salida = self.xml_texto texto
    c = TCPSocket.new ip, @puerto
    c.puts salida
    c.close
  end

  def broadcast_texto texto
    @threads << Thread.new do
      salida = self.xml_texto texto
      @s_broadcast_salida.send( salida, 0, '<broadcast>', @puerto)
    end
  end

  def broadcast_archivo ruta
    begin
      f = File.open ruta
    rescue
      raise 'no existe el archivo'
    end
    salida = self.xml_archivo f
    @threads << Thread.new do
      puts "enviando file por broadcast"
      @s_broadcast_salida.send( salida, 0, '<broadcast>', @puerto)
    end
  end

  def enviar_archivo ip, ruta
    begin
      f = File.open ruta
    rescue
      raise 'no existe el archivo'
    end
    salida = self.xml_archivo f
    @threads << Thread.new do
      c = TCPSocket.new ip, @puerto
      c.puts salida
      c.close
    end
  end

end


