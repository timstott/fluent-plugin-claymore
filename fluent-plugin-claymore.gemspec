lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name    = 'fluent-plugin-claymore'
  spec.version = '1.0.0'
  spec.authors = ['Timothy Stott']
  spec.email   = ['stott.timothy@gmail.com']

  spec.summary       = 'Fluentd parser plugin for Claymore Dual Miner logs'
  spec.description   = 'Extract time series metrics from Claymore Dual Miner logs'
  spec.homepage      = 'https://github.com/timstott/fluent-plugin-claymore'
  spec.license       = 'Apache-2.0'

  test_files, files  = `git ls-files -z`.split("\x0").partition do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.files         = files
  spec.executables   = files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = test_files
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.14'
  spec.add_development_dependency 'rake', '~> 12.0'
  spec.add_development_dependency 'rubocop', '~> 0.50.0'
  spec.add_development_dependency 'test-unit', '~> 3.0'
  spec.add_development_dependency 'timecop', '~> 0.9'
  spec.add_runtime_dependency 'fluentd', ['>= 0.14.10', '< 2']
end
