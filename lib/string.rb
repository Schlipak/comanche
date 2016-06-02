# coding: utf-8

module Comanche
  RIGHT_ARROW   ||= "\uE0B0".freeze
  LEFT_ARROW    ||= "\uE0B2".freeze
  RESET         ||= "\e[0m".freeze
  FG_CODE       ||= '3'
  BG_CODE       ||= '4'
  COLOR_CODES   ||= {
    :black      => '0',
    :red        => '1',
    :green      => '2',
    :yellow     => '3',
    :blue       => '4',
    :purple     => '5',
    :magenta    => '5',
    :cyan       => '6',
    :white      => '7'
  }
  MODES_CODES   ||= {
    :default    => '0',
    :bold       => '1',
    :dim        => '2',
    :italic     => '3',
    :underline  => '4',
    :reverse    => '7',
    :invisible  => '8',
    :strike     => '9'
  }
end

class String
  def getColorCode(h = {})
    code = "\e["
    options = []
    if not h[:mode].nil? then
      if h[:mode].is_a? Array then
        h[:mode].each do |m|
          options << Comanche::MODES_CODES[m.to_sym]
        end
      else
        options << Comanche::MODES_CODES[h[:mode]]
      end
    else
      options << Comanche::MODES_CODES[:default]
    end
    if not h[:color].nil? then
      options << Comanche::FG_CODE + Comanche::COLOR_CODES[h[:color]]
    end
    if not h[:background].nil? then
      options << Comanche::BG_CODE + Comanche::COLOR_CODES[h[:background]]
    end
    code += options.join(';') + 'm'
    return code
  end

  def colorize(h = {})
    code = self.getColorCode h
    code + self + Comanche::RESET
  end

  def colorize!(h = {})
    self.replace self.colorize(h)
  end

  def asciiBox(opts = {})
    str = String.new
    str += (opts[:corner] || '+')
    str += ((opts[:hori] || '-') * (self.length + 2))
    str += (opts[:corner] || '+')
    str += "\n"
    str += (opts[:vert] || '|')
    str += ' ' + self.chomp.colorize(opts) + ' '
    str += (opts[:vert] || '|')
    str += "\n"
    str += (opts[:corner] || '+')
    str += ((opts[:hori] || '-') * (self.length + 2))
    str += (opts[:corner] || '+')
    str += "\n"
    str
  end

  def powerline(opts = {})
    width = opts[:width] || 40
    arrowChar = Comanche::RIGHT_ARROW
    if opts[:arrow] == :left then
      arrowChar = Comanche::LEFT_ARROW
    end
    # Make text readable on light background terminals if requested color is :white
    if opts[:color] == :white then
      code = self.getColorCode :mode => :bold, :color => :black, :background => :white
    else
      code = self.getColorCode :mode => [:bold, :reverse], :color => opts[:color]
    end
    arrowColor = self.getColorCode(:color => opts[:color])
    if opts[:next] then
      arrowColor = self.getColorCode(:background => opts[:color], :color => opts[:next])
    end
    arrowColor = Comanche::RESET + arrowColor
    self.replace "#{code} %-#{width}s #{arrowColor + arrowChar + Comanche::RESET}" % self
    if opts[:newline] then self.replace "\n#{self}" end
    self
  end

  def removeColor
    self.gsub! /\e\[[\d;]+m/, ''
  end
end
