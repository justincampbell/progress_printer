# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "progress_printer/version"

Gem::Specification.new do |spec|
  spec.name          = "progress_printer"
  spec.version       = ProgressPrinter::VERSION
  spec.authors       = ["Justin Campbell"]
  spec.email         = ["justin@justincampbell.me"]

  spec.summary       = %q{Logs the progress of an operation, with estimated completion time.}
  spec.description   = spec.summary
  spec.homepage      = "https://github.com/justincampbell/progress_printer"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.15"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
