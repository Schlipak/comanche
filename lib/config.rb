# -*- coding: utf-8 -*-

require 'yaml'
require 'fileutils'

module Comanche
  DEFAULT_CONF = {
    'server' => {
      'port' => 6174,
      'verbose' => true,
      'timeout' => 20
    },
    'website' => {
      'root' => 'public/',
      'not_found' => '404.html'
    },
    'mods' => {
      'mod_dir' => true
    }
  }.freeze

  CONFIG_OPTIONS = {
    'server' => {
      'port' => 'Port number',
      'verbose' => 'Output verbose info',
      'timeout' => 'Request timeout time'
    },
    'website' => {
      'root' => 'Website root directory',
      'not_found' => '404 page'
    },
    'mods' => {
      'mod_dir' => 'Enable directory page'
    }
  }.freeze

  @@config = {}

  def self.config=(hash = {})
    @@config = Hash.new
    hash.each do |k, v|
      if CONFIG_OPTIONS.key? k then
        if not v.is_a? Hash then
          next
        end
        @@config[k.to_sym] = Hash.new
        STDERR.puts "[#{k.to_s.capitalize}]".colorize(:color => :purple)
        v.each do |opt, val|
          if CONFIG_OPTIONS[k].key? opt then
            @@config[k.to_sym][opt.to_sym] = val
            STDERR.puts "#{CONFIG_OPTIONS[k][opt].to_s.ljust(25)} => #{val.to_s.colorize(:color => :blue)}"
          else
            STDERR.puts "Unknown option \"#{k.to_s}/#{opt.to_s}\"".colorize(:color => :yellow)
          end
        end
        STDERR.puts
      else
        STDERR.puts "Unknown section \"#{k.to_s}\"".colorize(:color => :yellow)
      end
    end
  end

  def self.config
    @@config
  end

  def self.createTemplateConfig
    FileUtils.mkdir_p CONFIG_DIR
    File.open(CONFIG_FILE_PATH, 'w') do |fd|
      fd.puts "##\n## Comanche config file\n##\n\n"
      fd.puts DEFAULT_CONF.to_yaml
      fd.close
    end
  end

  def self.loadConfig
    if File.exist? CONFIG_FILE_PATH then
      begin
        STDERR.puts "Loading Comanche config".asciiBox(
          :mode => :bold
        )
        conf = YAML.load_file CONFIG_FILE_PATH
        self.config = conf
      rescue Exception => e
        STDERR.puts "Error parsing config file".colorize(:color => :red)
        STDERR.puts e.to_s.capitalize
      end
    else
      STDERR.puts "Config file not found, creating template at #{CONFIG_FILE_PATH}"
      Comanche.createTemplateConfig
    end
  end
end
