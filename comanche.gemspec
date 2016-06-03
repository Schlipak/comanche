# -*- coding: utf-8 -*-

require 'date'
require File.expand_path('../lib/server.rb', __FILE__)

Gem::Specification.new do |spec|
  spec.name             = 'comanche'
  spec.version          = Comanche::VERSION_NUMBER
  spec.date             = Date.today.to_s

  spec.authors          = ['Guillaume Schlipak']
  spec.email            = ['g.de.matos@free.fr']

  spec.summary          = %q{A pocket-sized HTTP server}
  spec.description      = %q{A pocket-sized Ruby HTTP server made just for fun}
  spec.homepage         = 'http://schlipak.github.io'
  spec.license          = 'MIT'

  spec.files            = Dir['templates/*'] + %w[
    lib/server.rb
    lib/comanche/config.rb
    lib/comanche/parser.rb
    lib/comanche/replycontent.rb
    lib/comanche/requesthandler.rb
    lib/comanche/string.rb
  ]

  spec.executables      = ['comanche']
  spec.require_paths    = ['lib']
end
