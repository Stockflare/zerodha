# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'zerodha/version'

Gem::Specification.new do |spec|
  spec.name          = 'zerodha'
  spec.version       = Zerodha::VERSION
  spec.authors       = ['Stockflare Ltd']
  spec.email         = ['info@stockflare.com']

  spec.summary       = 'Stockflare integration with Zerodha API '
  spec.description   = 'Stockflare integration with Zerodha API https://kite.trade/docs/connect/v1/#introduction'
  spec.homepage      = ''
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(spec|features)/})
  spec.require_paths = ['lib']
  spec.required_ruby_version = Gem::Requirement.new('>= 2.0.0')

  spec.add_runtime_dependency 'virtus', ['~> 1.0']
  spec.add_runtime_dependency 'multi_json', ['>= 1.0']
  spec.add_runtime_dependency 'yajl-ruby', ['~> 1.2']
  spec.add_runtime_dependency 'httparty'
  spec.add_runtime_dependency 'hashie'

  spec.add_development_dependency 'bundler', ['~> 1.6']
  spec.add_development_dependency 'rake', ['~> 10.3']
  spec.add_development_dependency 'rspec', ['~> 3.0']
  spec.add_development_dependency 'faker', ['~> 1.4']
  spec.add_development_dependency 'yard', ['~> 0.8']
  spec.add_development_dependency 'dotenv', ['~> 2.0']
  spec.add_development_dependency 'rubocop', ['~> 0.32']
  spec.add_development_dependency 'coveralls', ['~> 0.8']
  spec.add_development_dependency 'factory_girl', ['~> 4.5']
  spec.add_development_dependency 'pry-byebug'
  spec.add_development_dependency 'memcached'
end
