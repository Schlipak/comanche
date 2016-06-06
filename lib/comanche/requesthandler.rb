# -*- coding: utf-8 -*-

require 'addressable/uri'
require 'socket'
require 'timeout'

require_relative '../comanche'

module Comanche
  class RequestHandler
    attr_accessor :socket, :server, :thread, :ip, :port, :request

    def initialize(socket, server)
      @socket = socket
      @server = server
      self.start
    end

    def start
      Thread.new do
        begin
          @thread = Thread.current
          @server.threads << @thread
          self.run
        rescue => e
          STDERR.puts e.inspect
          STDERR.puts e.backtrace
        end
      end
    end

    def requestFilePath(request)
      rquri = request.split(' ')[1]
      path = Addressable::URI.parse(rquri).path

      clean = Array.new
      path.split('/').each do |part|
        next if part.empty? || part == '.'
        part == '..' ? clean.pop : clean << part
      end

      File.join(@server.root, *clean)
    end

    def getContent(request)
      path = self.requestFilePath request
      ReplyContent.new path
    end

    def getReplyColor(status)
      case status
      when 100..299 then return :green
      when 300..399 then return :purple
      when 400..499 then return :yellow
      when 500..599 then return :red
      else return :purple
      end
    end

    def self.logLine(txt, color, addContent = nil)
      begin
        io = StringIO.new

        if not Server.daemon? then
          io.print "#{Time.now.strftime '%H:%M:%S'}".powerline({
            :color => :white,
            :width => 8,
            :newline => false,
            :arrow => :left,
            :next => color
          })
          io.puts txt.powerline({
            :color => color,
            :width => 40,
            :newline => false
          })
        else
          io.print "#{Time.now.strftime '%D %H:%M:%S'} | "
          io.puts txt
        end
        io.puts addContent.chomp unless addContent.nil?
        io.puts

        STDERR.puts io.string
      rescue => e
        STDERR.puts e.to_s
      end
    end

    def logLine(txt, color, addContent = nil)
      RequestHandler.logLine(txt, color, addContent)
    end

    def processRequest
      rq = @request.split(' ').first
      case rq
      when 'GET'
        self.httpGET
      end
    end

    def httpGET
      content = self.getContent(@request)
      response = "HTTP/1.1 #{content.status} #{content.message}\r\n" +
                 "Content-Type: #{content.type}\r\n" +
                 "Content-Length: #{content.size}\r\n" +
                 "Connection: #{content.conn || 'close'}\r\n"
      @socket.print response
      @socket.print "\r\n"
      @socket.print content.data

      logMsg = "Path: " + content.path + "\n\n" + response.chomp
      self.logLine("Comanche → #{@ip}:#{@port}", self.getReplyColor(content.status), logMsg)
    end

    def run
      begin
        # TODO: Reconsider the use of timeout here
        # We can't know before receiving the request if a timeout should be enforced
        # eg. Keep-alive type connections should be exempted
        # note: Somehow, keep-alive connections like mp3 transfers seem to sometimes
        # work even though Comanche will log a timeout error?
        Timeout::timeout(Comanche.config[:server][:timeout]) do
          @request = @socket.gets

          @port, @ip = Socket.unpack_sockaddr_in(@socket.getpeername)
          self.logLine("Comanche ← #{@ip}:#{@port}", :blue, @request.to_s)

          self.processRequest
        end
      rescue Timeout::Error
        @port, @ip = Socket.unpack_sockaddr_in(@socket.getpeername)
        self.logLine("Comanche → #{@ip}:#{@port}", :red, "Request \"#{@request.to_s.chomp}\" timed out")

        if not @socket.closed? then
          data = '500 Server timeout'
          response = "HTTP/1.1 500 Server timeout\r\n" +
                     "Content-Type: text/plain\r\n" +
                     "Content-Length: #{data.bytesize}\r\n" +
                     "Connection: close\r\n"
          @socket.print response
          @socket.print "\r\n"
          @socket.print data
        end
      rescue SystemCallError => e
        self.logLine("Comanche → #{ip}:#{port}", :red, e.to_s.capitalize)
      ensure
        @socket.close
        @server.threads.delete @thread
      end # begin
    end # self.run
  end # class RequestHandler
end # Module
