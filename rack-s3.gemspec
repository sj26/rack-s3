# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "rack/s3/version"

Gem::Specification.new do |s|
  s.name        = "rack-s3"
  s.version     = Rack::S3::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Larry Marburger"]
  s.email       = ["larry@marburger.cc"]
  s.homepage    = "http://developmentastic.com"
  s.summary     = %q{A Rack::Static like middleware for serving assets from S3}
  s.description = %q{Serve files from an S3 bucket as if they were local assets similar to Rack::Static.}

  s.add_dependency 'aws-s3'
  s.add_dependency 'rack'

  s.add_development_dependency 'webmock'
  s.add_development_dependency 'vcr'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
