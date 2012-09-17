# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'enum_accessor/version'

Gem::Specification.new do |gem|
  gem.name          = 'enum_accessor'
  gem.version       = EnumAccessor::VERSION
  gem.authors       = ['Kenn Ejima']
  gem.email         = ['kenn.ejima@gmail.com']
  gem.description   = %q{Simple enum fields for ActiveRecord}
  gem.summary       = %q{Simple enum fields for ActiveRecord}
  gem.homepage      = 'https://github.com/kenn/enum_accessor'

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ['lib']

  gem.add_runtime_dependency 'activesupport', '>= 3.0.0'

  gem.add_development_dependency 'activerecord', '>= 3.0.0'
  gem.add_development_dependency 'rspec'
  gem.add_development_dependency 'sqlite3'
end
