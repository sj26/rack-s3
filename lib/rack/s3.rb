require 'rack'
require 'aws/s3'

module Rack
  class S3

    def initialize(app, options={})
      @app    = app
      @prefix = options[:prefix]
      @bucket = options[:bucket]

      AWS::S3::Base.establish_connection!(
        :access_key_id     => options[:access_key_id],
        :secret_access_key => options[:secret_access_key])
    end

    def call(env)
      dup._call env
    end

    def _call(env)
      @env = env

      if can_serve?
        [ 200, headers, object.value ]
      else
        @app.call env
      end

    rescue AWS::S3::NoSuchKey
      not_found
    end

    def headers
      about = object.about

      { 'Content-Type'   => about['content-type'],
        'Content-Length' => about['content-length'],
        'Etag'           => about['etag'],
        'Last-Modified'  => about['last-modified'],
        'Cache-Control'  => 'public; max-age=2592000'  # cache image for a month
      }
    end

    def can_serve?
      path_info.index(@prefix) == 0
    end

    def path_info
      @env['PATH_INFO']
    end

    def path
      path_info.split('/').last
    end

    def object
      @object ||= AWS::S3::S3Object.find(path, @bucket)
    end

    def not_found
      body = "File not found: #{ path_info }\n"

      [ 404,
        { 'Content-Type'   => "text/plain",
          'Content-Length' => body.size.to_s },
        [ body ]]
    end

  end
end
