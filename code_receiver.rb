require "socket"

class CodeReceiver
  EXTRACTION_PATTERN = /GET \/callback\?code=(.*?) HTTP.*/

  def initialize(port:)
    @server = TCPServer.new("127.0.0.1", port)
  end

  def listen
    @thread = Thread.new do
      session = @server.accept
      request = session.gets

      match = EXTRACTION_PATTERN.match(request)
      @code = match[1]

      session.print("HTTP/1.1 200/OK\r\n")
      session.print("Content-Type: text/html\r\n")
      session.print("\r\n")
      session.print("You may close this now. Received code: #{@code}\r\n\r\n")

      session.close
    end
  end

  def code
    @thread.join
    @code
  end
end


