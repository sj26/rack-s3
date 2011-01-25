require 'rubygems'
require 'test/unit'

require 'bundler/setup'
Bundler.require :development

require 'rack/mock'
require 'rack/s3'

class Test::Unit::TestCase

  VCR.config do |c|
    c.cassette_library_dir = 'test/vcr_cassettes'
    c.stub_with :webmock
    c.default_cassette_options = { :record => :none }
  end

end
