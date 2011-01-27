require 'test_helper'

class RackS3Test < Test::Unit::TestCase

  def mock_request(path)
    Rack::MockRequest.new(app).get path, :lint => true
  end

  def app
    Rack::S3.new :bucket            => 'rack-s3',
                 :access_key_id     => 'abc123',
                 :secret_access_key => 'abc123'
  end

  def teardown
    AWS::S3::Base.disconnect!
  end


  context 'A request for a nonexistent key' do
    subject do
      VCR.use_cassette 'not_found' do
        mock_request '/not_found.png'
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
      VCR.use_cassette 'clear' do
        mock_request '/clear.png'
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
      VCR.use_cassette 'nested_clear' do
        mock_request '/very/important/files/clear.png'
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
      VCR.use_cassette 'clear' do
        unmapped_app = app
        mapped_app   = Rack::Builder.new do
                         map '/mapped/app' do
                           run unmapped_app
                         end
                       end

        Rack::MockRequest.new(mapped_app).get '/mapped/app/clear.png'
      end
    end

    should 'render the file' do
      assert_equal 200, subject.status
    end
  end

  context 'Without AWS credentials' do
    subject do
      app = Rack::S3.new :bucket => 'rack-s3'

      Rack::MockRequest.new(app).get '/clear.png'
    end

    should 'not attempt to establish a connection to AWS' do
      assert_raise AWS::S3::NoConnectionEstablished do
        subject
      end
    end
  end

end
