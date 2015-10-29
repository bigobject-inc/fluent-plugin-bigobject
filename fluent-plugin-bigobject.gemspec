# -*- encoding: utf-8 -*-
Gem::Specification.new do |gem|
  gem.name          = "fluent-plugin-bigobject"
  gem.version       = "0.0.7"
  gem.authors       = ["Andrea Sung"]
  gem.email         = ["andrea@bigobject.io"]
  gem.description   = %q{Fluentd output plugin to insert BIGOBJECT }
  gem.summary       = %q{Fluentd output plugin to insert BIGOBJECT}
  gem.homepage      = "https://github.com/macrodatalab/fluent-plugin-bigobject"
  gem.license       = "MIT"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_runtime_dependency "fluentd"
  gem.add_runtime_dependency "rest-client"
  gem.add_runtime_dependency "json"
  gem.add_runtime_dependency "avro"
  gem.add_development_dependency "rake"
end
