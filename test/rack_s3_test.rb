require 'test_helper'

class DummyApp
  def call(env)
    [ 200, {}, [ "Hello World" ]]
  end
end

class RackS3Test < Test::Unit::TestCase

  def app
    options = { :bucket            => 'rack-s3',
                :access_key_id     => 'abc123',
                :secret_access_key => 'abc123' }

    Rack::Builder.new do
      use Rack::S3, options
      run DummyApp.new
    end
  end

  def request
    Rack::MockRequest.new app
  end

  def test_return_not_found_for_nonexistent_keys
    response = VCR.use_cassette 'not_found', :record => :none do
      request.get '/not_found.png'
    end

    assert_equal 404, response.status
    assert_equal "File not found: /not_found.png\n", response.body
    assert_equal 'text/plain', response.headers['Content-Type']
    assert_equal '31', response.headers['Content-Length']
  end

  def test_serve_keys_from_s3
    response = VCR.use_cassette 'clear', :record => :none do
      request.get '/clear.png'
    end

    assert_equal 200, response.status
    assert_equal 'public; max-age=2592000', response.headers['Cache-Control']
    assert_not_nil response.body

    %w(Content-Type Last-Modified Last-Modified Etag).each do |header|
      assert_not_nil response.headers[header]
    end
  end

  def test_serve_nested_keys_from_s3
    response = VCR.use_cassette 'nested_clear', :record => :none do
      request.get '/very/important/files/clear.png'
    end

    assert_equal 200, response.status
    assert_equal 'public; max-age=2592000', response.headers['Cache-Control']
    assert_not_nil response.body

    %w(Content-Type Last-Modified Last-Modified Etag).each do |header|
      assert_not_nil response.headers[header]
    end
  end

end
