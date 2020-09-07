Gem::Specification.new do |s|
  s.name     = "rack-s3"
  s.version  = "1.0.0"
  s.authors  = ["Larry Marburger", "Samuel Cochran"]
  s.email    = ["larry@marburger.cc", "sj26@sj26.com"]
  s.homepage = "https://github.com/sj26/rack-s3"
  s.summary  = "Serve static files from S3 via Rack"

  s.files = Dir["README.md", "LICENSE", "lib/**/*"]

  s.add_dependency "rack"
  s.add_dependency "aws-sdk-s3"

  s.add_development_dependency "rake"
  s.add_development_dependency "rspec"
  s.add_development_dependency "rack-test"
  s.add_development_dependency "vcr"
  s.add_development_dependency "webmock"
end
