# -*- encoding: utf-8 -*-
require File.expand_path('../lib/rtask/version', __FILE__)

Gem::Specification.new do |gem|
  gem.name	    	= "rtask"
  gem.authors       = ["Michael Pevzner"]
  gem.email         = ["mihapbox@gmail.com"]
  gem.description   = "rake for sysadmin tasks"
  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.require_paths = ["lib"]
  gem.version       = RTask::VERSION
  gem.summary       = "makes sysadmins happy"
end
