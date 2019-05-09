# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name          = 'logstash-filter-elasticsearchslowlog'
  s.version       = '0.4.0'
  s.licenses      = ['Apache-2.0']
  s.summary       = 'elasticsearch slowlog parser'
  s.description   = 'elasticsearch slowlog parser'
  s.homepage      = 'https://github.com/ananthakumaran/logstash-filter-elasticsearchslowlog'
  s.authors       = ['Anantha Kumaran']
  s.email         = 'ananthakumaran@gmail.com'
  s.require_paths = ['lib']

  # Files
  s.files = Dir['lib/**/*', 'spec/**/*', 'vendor/**/*', '*.gemspec', '*.md', 'CONTRIBUTORS', 'Gemfile', 'LICENSE', 'NOTICE.TXT']
  # Tests
  s.test_files = s.files.grep(%r{^(test|spec|features)/})

  # Special flag to let us know this is actually a logstash plugin
  s.metadata = { "logstash_plugin" => "true", "logstash_group" => "filter" }

  # Gem dependencies
  s.add_runtime_dependency "deepsort", "0.4.0"
  s.add_runtime_dependency "logstash-core-plugin-api", ">= 1.20", "<= 2.99"
  s.add_development_dependency 'logstash-devutils'
  s.add_development_dependency 'appraisal'
end
