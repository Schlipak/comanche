# -*- coding: utf-8 -*-

require 'erb'

require_relative 'config'
require_relative '../comanche'

module Comanche
  class ReplyContent
    CONTENT_TYPES = {
      'html' => 'text/html',
      'txt' => 'text/plain',
      'png' => 'image/png',
      'jpg' => 'image/jpeg',
      'jpeg' => 'image/jpeg',
      'gif' => 'image/gif',
      'svg' => 'image/svg+xml',
      'ico' => 'image/x-icon',
      'css' => 'text/css',
      'js' => 'text/javascript',
      'sh' => 'text/x-shellscript',
      'fish' => 'text/x-shellscript',
      'mp3' => 'audio/mpeg3'
    }
    DEFAULT_CONTENT_TYPE = 'application/octet-stream'

    attr_accessor :status,
                  :message,
                  :data,
                  :type,
                  :size,
                  :file,
                  :notfound,
                  :conn,
                  :path

    def initialize(path)
      @notfound = File.join(Server.root, Comanche.config.dig(:website, :not_found).to_s)
      @path = (path or @notfound)
      @conn = nil

      begin
        self.findData
      rescue => err
        puts err
      end
    end

    # TODO: REWRITE THIS MONTROSITY
    # LIKE WRITE AN ACTUAL ROUTING SYSTEM
    def findData
      if File.exist? @path and not File.directory? @path then
        @data = File.read(@path)
        @status = 200
        @message = 'OK'
        @type = ReplyContent::contentType(@path)
        @size = @data.bytesize
        if @type == CONTENT_TYPES['mp3'] then
          @conn = 'keep-alive'
        end
      elsif File.directory? @path then
        ppath = @path
        @path = File.join(@path, 'index.html')
        return true if self.findData
        if not Comanche.config.dig(:mods, :mod_dir) then
          @path = 'FORBIDDEN'
          @data = 'Directory listing has been disabled'
          @type = CONTENT_TYPES['txt']
          @status = 403
          @message = 'Forbidden'
          @size = @data.bytesize
          return false
        end
        @path = ppath
        @data = self.generateDirectoryPage(@path)
        @status = 200
        @message = 'OK'
        @type = CONTENT_TYPES['html']
        @size = @data.bytesize
      elsif @path == "#{Server.root}/teapot" then
        @path = 'TEAPOT'
        @data = "I'm a teapot"
        @type = CONTENT_TYPES['txt']
        @status = 418
        @message = "I'm a teapot"
        @size = @data.bytesize
      else
        requestType = ReplyContent::contentType(@path)
        if requestType == CONTENT_TYPES['html'] or requestType == DEFAULT_CONTENT_TYPE then
          @path = @notfound
          @data = File.read(@path)
          @type = CONTENT_TYPES['html']
          dataNotFound = false
        else
          @data = "#{@path.sub Server.root, ''}: file not found"
          @type = CONTENT_TYPES['txt']
          dataNotFound = true
        end
        @status = 404
        @message = 'Not Found'
        @size = @data.bytesize
        return dataNotFound
      end
      true
    end

    def generateDirectoryPage(path)
      if Dir.entries(path).nil? then
        return 'Cannot open directory'
      end
      RequestHandler.logLine("Generating #{path}", :purple)
      templatePath = File.join(File.dirname(__FILE__), '../../templates/dir.html.erb')
      if not File.exist? templatePath then
        return "Directory template not found"
      end
      template = File.read templatePath
      data = {
        :path => path,
        :entries => Dir.entries(path).sort,
        :title => path.sub(Server.root, '/').sub('//', '/'),
        :comanche => Comanche
      }
      ERB.new(template).result(binding)
    end

    def self.contentType(path)
      ext = File.extname(path).split('.').last
      CONTENT_TYPES.fetch(ext, DEFAULT_CONTENT_TYPE)
    end

    def to_s
        [
            "File:\t#{@path}",
            "Status:\t#{@status} #{@message}",
            "Type:\t#{@type}",
            "Size:\t#{@size} bytes"
        ].join "\n"
    end
  end
end
