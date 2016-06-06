# -*- coding: utf-8 -*-

require 'optparse'

require_relative '../comanche'

module Comanche
  class ParamParser
    PARAMS = "[flags] [port]".freeze
    DESCR = "\thost\t\t\tHost to bind the server to\n\tport\t\t\tPort to listen to\n\n".freeze
    USAGE = "USAGE\n\tcomanche #{PARAMS}\n\nDESCRIPTION\n#{DESCR}OPTIONS\n"

    VERSION = '1.0'.freeze

    def initialize
      @options = {}
      @parser = nil
    end

    def self.killDaemon
      pidfile = File.expand_path(Server::PID_FILE_PATH)
      case Server.pidStatus(pidfile)
      when :exited
        STDERR.puts 'No running daemon to kill'.colorize(:color => :green)
      when :dead
        File.delete(pidfile)
        STDERR.puts 'No running daemon to kill'.colorize(:color => :green)
      when :running, :not_owned
        pid = File.read(pidfile).to_i
        STDERR.puts "Sending Interrupt signal to #{pid}..."
        Process.kill(:SIGINT, pid)
        loop until [:exited, :dead].include? Server.pidStatus(pidfile)
        STDERR.puts "Server instance #{pid} stopped".colorize(:color => :green)
      end
    end

    def parse!
      begin
        @parser = OptionParser.new(USAGE, 23, "\t") do |opts|
          opts.on('-h', '--help', 'Show the help') do |v|
            STDERR.puts @parser.help
            exit! 0
          end

          opts.on('-v', '--version', 'Show the program version') do |v|
            STDERR.puts "http.rb v#{VERSION}"
            exit! 0
          end

          opts.on('-d', '--daemon', 'Run as daemon') do |v|
            @options[:daemon] = v
          end

          opts.on('-k', '--kill', 'Kills the running daemon') do
            ParamParser.killDaemon
            exit! 0
          end

          opts.on('-r', '--restart', 'Restart the server') do
            ParamParser.killDaemon
            puts
          end

          opts.on('-t', '--template', 'Create a template configuration file') do
            Comanche.createTemplateConfig
            exit! 0
          end
        end
        @parser.parse!
      rescue OptionParser::InvalidOption => e
        STDERR.puts e.to_s.capitalize.colorize(:color => :red)
        exit! 1
      ensure
        return @options
      end
    end

    def help
      @parser.help
    end
  end
end
