# -*- encoding: utf-8 -*-
require File.expand_path('../lib/tandem-core-rails/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Jason Chen", "Byron Milligan"]
  gem.email         = ["support@stypi.com"]
  gem.description   = "Tandem core functions Rails 3"
  gem.summary       = "Tandem core functions Rails 3"
  gem.homepage      = "https://github.com/stypi/tandem-core"

  gem.files         = Dir["{lib,vendor}/**/*"] + ["README.md"]
  gem.name          = "tandem-core-rails"
  gem.require_paths = ["lib"]
  gem.version       = Tandem::Rails::VERSION

  gem.add_dependency "railties", "~> 3.1"
  gem.add_dependency "underscore-rails", "~> 1.4.3"
end
