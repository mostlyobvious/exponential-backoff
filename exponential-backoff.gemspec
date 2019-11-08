# -*- encoding: utf-8 -*-
require File.expand_path('../lib/exponential_backoff/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Paweł Pacana"]
  gem.email         = ["pawel.pacana@gmail.com"]
  gem.summary       = %q{Exponential backoff algorithm for better reconnect intervals.}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "exponential-backoff"
  gem.require_paths = ["lib"]
  gem.version       = ExponentialBackoff::VERSION

  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'test-unit'
end
