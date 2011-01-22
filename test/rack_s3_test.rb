require 'test_helper'
require 'rack/mock'

class DummyApp
  def call(env)
    [ 200, {}, [ "Hello World" ]]
  end
end

class RackS3Test < Test::Unit::TestCase

  def app
    # HACK: Use your S3 credentials to run the test suite. Should use a
    # recording library like VCR.
    options = { :prefix => '/s3',
                :bucket => 'rack-s3',
                :access_key_id     => 'insert_access_key_here',
                :secret_access_key => 'insert_secret_here' }

    Rack::MockRequest.new Rack::S3.new(DummyApp.new, options)
  end

  def test_serve_files_from_s3
    response = app.get '/s3/clear.png'

    assert_equal 200, response.status
    assert_equal 'public; max-age=2592000', response.headers['Cache-Control']
    assert_not_nil response.body

    %w(Content-Type Last-Modified Last-Modified Etag).each do |header|
      assert_not_nil response.headers[header]
    end
  end

  def test_ignore_requests_outside_of_prefix
    response = app.get '/ignore_me'

    assert_equal 'Hello World', response.body
  end

  def test_return_not_found_for_nonexistent_files
    response = app.get '/s3/nil.png'

    assert_equal 404, response.status
    assert_equal "File not found: /s3/nil.png\n", response.body
    assert_equal 'text/plain', response.headers['Content-Type']
    assert_equal '28', response.headers['Content-Length']
  end

end
