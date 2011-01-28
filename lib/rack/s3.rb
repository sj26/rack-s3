require 'rack'
require 'aws/s3'
require 'cgi'

module Rack
  class S3

    def initialize(options={})
      @bucket = options[:bucket]

      establish_aws_connection(options[:access_key_id],
                               options[:secret_access_key])
    end

    def establish_aws_connection(access_key_id, secret_access_key)
      return unless access_key_id && secret_access_key

      AWS::S3::Base.establish_connection!(
        :access_key_id     => access_key_id,
        :secret_access_key => secret_access_key)
    end

    def call(env)
      dup._call env
    end

    def _call(env)
      @env = env
      [ 200, headers, object.value ]
    rescue AWS::S3::NoSuchKey
      not_found
    end

    def headers
      about = object.about

      { 'Content-Type'   => about['content-type'],
        'Content-Length' => about['content-length'],
        'Etag'           => about['etag'],
        'Last-Modified'  => about['last-modified']
      }
    end

    def path_info
      CGI.unescape @env['PATH_INFO']
    end

    def path
      path_info[0...1] == '/' ? path_info[1..-1] : path_info
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
