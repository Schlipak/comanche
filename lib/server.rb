# -*- coding: utf-8 -*-

require 'socket'

require_relative 'requesthandler'
require_relative 'replycontent'
require_relative 'string'

module Comanche
  VERSION_NUMBER = '0.1.2'
  VERSION_NAME = 'Arctic Fox'

  class Server
    WEB_ROOT = './public'
    LOG_FILE_PATH = 'comanche.log'
    PID_FILE_PATH = 'comanche.lck'

    attr_accessor :server, :port, :threads, :root, :logfile, :pidfile

    def initialize(port, opts)
      @port = port
      if @port <= 0 or @port > 49151 then
        STDERR.puts "Port number out of range [1-49151] (Got #{@port})".colorize(:color => :red)
        exit! 1
      end
      @threads = Array.new
      @root = Comanche.config[:website][:root] || WEB_ROOT
      @@root = @root

      @daemonize = opts[:daemon]
      @@daemonize = @daemonize
      @logfile = File.expand_path(LOG_FILE_PATH)
      @pidfile = File.expand_path(PID_FILE_PATH)

      @@old_stderr = nil
      @@old_stdout = nil

      self.initTrap
      self.createServer
    end

    def initTrap
      trap :SIGINT do
        self.restoreOutput unless @@old_stderr.nil?
        puts "\b\b  \n[INFO] Shutting down server".colorize(:color => :yellow)
        @threads.each do |th|
          puts "Waiting for #{th}".colorize(:color => :yellow, :mode => :dim)
          th.join
        end
        puts "\b\b[INFO] Server stop".colorize(:color => :yellow)
        exit 0
      end
    end

    def daemon?
      @daemonize == true
    end

    def self.daemon?
      @@daemonize == true
    end

    def writePid
      begin
        File.open(@pidfile, File::CREAT | File::EXCL | File::WRONLY) do |fd|
          fd.write Process.pid.to_s
        end
        at_exit do
          File.delete(@pidfile) if File.exists?(@pidfile)
        end
      rescue Errno::EEXIST
        self.checkPid
        retry
      end
    end

    def checkPid
      case Server.pidStatus(@pidfile)
      when :running, :not_owned
        STDERR.puts 'An instance of Comanche is already running'.colorize(:color => :red, :mode => :bold)
        STDERR.puts "Check #{@pidfile}".colorize(:color => :red)
        exit! 1
      when :dead
        File.delete @pidfile
      end
    end

    def self.pidStatus(path)
      return :exited unless File.exists?(path)
      pid = File.read(path).to_i
      return :dead if pid == 0
      Process.kill(0, pid)
      :running
    rescue Errno::ESRCH
      :dead
    rescue Errno::EPERM
      :not_owned
    end

    def daemonize
      STDERR.puts "Daemonizing server now. Quit with '#{'comanche --kill'.colorize(:mode => :italic)}'"
      Process.daemon(true, true)
    end

    def redirectOutput
      FileUtils.touch @logfile
      File.chmod 0644, @logfile

      @@old_stderr = $stderr.clone
      @@old_stdout = $stdout.clone

      $stderr.reopen(@logfile, 'a')
      $stdout.reopen($stderr)
      $stdout.sync = $stderr.sync = true
    end

    def restoreOutput
      $stderr.reopen(@@old_stderr)
      $stdout.reopen(@@old_stdout)
    end

    def createServer
      self.checkPid
      tries = 3
      begin
        @server = TCPServer.new port
        STDERR.puts "Server listening on localhost:#{port}".asciiBox(
          :mode => :bold,
          :color => :green
        )
        STDERR.puts
      rescue Errno::EACCES => e
        STDERR.puts "#{e.to_s.capitalize}".colorize(:mode => :bold, :color => :red)
        STDERR.puts "Note: Only root can bind to ports 1 to 1023" unless @port > 1023
        exit! 1
      rescue Errno::EADDRINUSE => e
        if tries == 0 then
          STDERR.puts "#{e.to_s.capitalize}".colorize(:mode => :bold, :color => :red)
          exit! 1
        end
        STDERR.puts "#{e.to_s.capitalize}, retrying... (#{tries})"
        sleep 0.5
        tries -= 1
        retry
      ensure
        return self
      end
    end

    def self.root
      @@root
    end

    def run!
      self.checkPid
      self.daemonize if @daemonize
      self.writePid
      if @daemonize then
        self.redirectOutput
      end
      loop do
        sock = @server.accept
        RequestHandler.new(sock, self)
      end
    end
  end
end
