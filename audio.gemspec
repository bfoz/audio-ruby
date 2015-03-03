# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
    spec.name          = "audio"
    spec.version       = '0.2'
    spec.authors       = ["Brandon Fosdick"]
    spec.email         = ["bfoz@bfoz.net"]
    spec.summary       = %q{Cross-platform Audio Device Input and Output}
    spec.description   = %q{Access all of your audio devices from the comfort of Ruby}
    spec.homepage      = "http://github.com/bfoz/audio-ruby"
    spec.license       = "BSD"

    spec.files         = `git ls-files -z`.split("\x0")
    spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
    spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
    spec.require_paths = ["lib"]

    spec.add_development_dependency "bundler", "~> 1.7"
    spec.add_development_dependency "rake", "~> 10.0"
end
