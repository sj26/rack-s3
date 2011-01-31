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
  s.description = %q{Rack::S3 is a middleware for serving assets from an S3 bucket. Why would you want to bypass a perfectly good CDN? For stacking behind other middlewares, of course! Drop it behind Rack::Thumb for dynamic thumbnails without the mess of pregenerating.}

  s.add_dependency 'aws-s3'
  s.add_dependency 'rack'

  s.add_development_dependency 'shoulda'
  s.add_development_dependency 'webmock'
  s.add_development_dependency 'vcr'
  s.add_development_dependency 'rocco'
  s.add_development_dependency 'pygmentize'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
