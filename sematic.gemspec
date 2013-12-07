# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "semantic"

spec = Gem::Specification.new do |s|
  # Metadata
  s.name        = "semantic"
  s.version     = Semantic::VERSION
  s.authors     = ["Pieter van de Bruggen"]
  s.email       = ["pieter@puppetlabs.com"]
  s.homepage    = "https://github.com/puppetlabs/semantic-gem"
  s.summary     = "Useful tools for working with Semantic Versions."
  # s.description = %q{TODO: Write a gem description}

  # Manifest
  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {spec}/*_spec.rb`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  s.require_paths = ["lib"]

  # Dependencies
  s.required_ruby_version = '>= 1.8.7'

  s.add_development_dependency "rake"
  s.add_development_dependency "rspec"
  s.add_development_dependency "simplecov"
  s.add_development_dependency "cane"
  s.add_development_dependency "yard"
  s.add_development_dependency "redcarpet"
end
