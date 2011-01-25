require 'test_helper'

class RackS3Test < Test::Unit::TestCase

  def app
    options = { :bucket            => 'rack-s3',
                :access_key_id     => 'abc123',
                :secret_access_key => 'abc123' }

    Rack::Builder.new do
      use Rack::S3, options
      run lambda { [ 200, {}, [ "Hello World" ]] }
    end
  end

  def mapped_app
    # #app isn't available inside the block below.
    unmapped_app = app

    Rack::Builder.new do
      map '/mapped/app' do
        run unmapped_app
      end
    end
  end


  context 'A request for a nonexistent key' do
    subject do
      VCR.use_cassette 'not_found', :record => :none do
        Rack::MockRequest.new(app).get '/not_found.png'
      end
    end

    should 'render a not found response' do
      assert_equal 404, subject.status
      assert_equal "File not found: /not_found.png\n", subject.body

      assert_equal 'text/plain', subject.headers['Content-Type']
      assert_equal '31',         subject.headers['Content-Length']
    end
  end

  context 'A request for a key' do
    subject do
      VCR.use_cassette 'clear', :record => :none do
        Rack::MockRequest.new(app).get '/clear.png'
      end
    end

    should 'render the file' do
      assert_equal 200, subject.status
      assert_equal 'public; max-age=2592000', subject.headers['Cache-Control']
      assert_not_nil subject.body

      %w(Content-Type Last-Modified Last-Modified Etag).each do |header|
        assert_not_nil subject.headers[header]
      end
    end
  end

  context 'A request for a nested key' do
    subject do
      VCR.use_cassette 'nested_clear', :record => :none do
        Rack::MockRequest.new(app).get '/very/important/files/clear.png'
      end
    end

    should 'render the file' do
      assert_equal 200, subject.status
      assert_equal 'public; max-age=2592000', subject.headers['Cache-Control']
      assert_not_nil subject.body

      %w(Content-Type Last-Modified Last-Modified Etag).each do |header|
        assert_not_nil subject.headers[header]
      end
    end
  end

  context 'A request to a mapped app' do
    subject do
      VCR.use_cassette 'clear', :record => :none do
        Rack::MockRequest.new(mapped_app).get '/mapped/app/clear.png'
      end
    end

    should 'render the file' do
      assert_equal 200, subject.status
    end
  end

end
