# coding: utf-8

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'libis/tools/version'

Gem::Specification.new do |spec|
  spec.name          = 'libis-tools'
  spec.version       = ::Libis::Tools::VERSION
  spec.date          = Date.today.to_s

  spec.summary       = %q{LIBIS toolbox.}
  spec.description   = %q{Some tool classes for other LIBIS gems.}

  spec.authors       = ['Kris Dekeyser']
  spec.email         = ['kris.dekeyser@libis.be']
  spec.homepage      = 'https://github.com/Kris-LIBIS/LIBIS_Tools'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})

  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.7'
  spec.add_development_dependency 'rake', '~> 10.3'
  spec.add_development_dependency 'rspec', '~> 3.1'
  spec.add_development_dependency 'simplecov', '>= 0.9'

  spec.add_runtime_dependency 'backports', '~> 3.6'
  spec.add_runtime_dependency 'savon', '~> 2.0'
  spec.add_runtime_dependency 'nokogiri'
  spec.add_runtime_dependency 'gyoku'
  spec.add_runtime_dependency 'nori'

end
