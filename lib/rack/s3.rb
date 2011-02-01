# **Rack::S3** is a middleware for serving assets from an S3 bucket. Why would
# you want to bypass a perfectly good CDN? For stacking behind other
# middlewares, of course! Drop it behind Rack::Thumb for dynamic thumbnails
# without the mess of pregenerating.
#
### Usage
#
# Rack::S3 assumes it's the final endpoint. Use `run` instead of `use` to mount
# it. This is less than ideal. It's still a work in progress.
#
#     use Rack::Thumb
#     run Rack::S3.new(:bucket => 'my-special-things')
#
# You probably don't want it responding to _all_ requests, so mount it at a
# given path prefix using Rack::Builder.
#
#     use Thumber
#
#     class Thumber
#       def initialize(app)
#         @app = stacked_app app
#       end
#
#       def stacked_app(app)
#         Rack::Builder.new do
#           map '/thumb' do
#             use Rack::Thumb
#             run Rack::S3.new(:bucket => 'my-special-things')
#           end
#
#           # Ignore all other requests
#           map '/' do
#             run lambda { |env| app.call env }
#           end
#         end
#       end
#
#       def call(env)
#         @app.call env
#       end
#     end

# `Rack::S3.new` needs a bucket name.
#
#     Rack::S3.new :bucket => 'my-special-things'
#
# Optionally, it can take your S3 credentials and establish a connection to S3
# using AWS::S3.
#
#     Rack::S3.new :bucket => 'my-special-things',
#                  :access_key_id    => 'abc123',
#                  :secret_access_ke => 'itsasecret'
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

    # Say great things about `call`
    def call(env)
      dup._call env
    end

    # Say great things about `_call`
    def _call(env)
      @env = env
      [ 200, headers, object.value ]
    rescue AWS::S3::NoSuchKey
      not_found
    end

    # Say great things about `headers`
    def headers
      about = object.about

      { 'Content-Type'   => about['content-type'],
        'Content-Length' => about['content-length'],
        'Etag'           => about['etag'],
        'Last-Modified'  => about['last-modified']
      }
    end

    # Say great things about `path_info`
    def path_info
      CGI.unescape @env['PATH_INFO']
    end

    # Say great things about `path`
    def path
      path_info[0...1] == '/' ? path_info[1..-1] : path_info
    end

    # Say great things about `object`
    def object
      @object ||= AWS::S3::S3Object.find(path, @bucket)
    end

    # Say great things about `not_found`
    def not_found
      body = "File not found: #{ path_info }\n"

      [ 404,
        { 'Content-Type'   => "text/plain",
          'Content-Length' => body.size.to_s },
        [ body ]]
    end

  private

    # Ssshhh... this method is private. Say great things about
    # `establish_aws_connection`
    def establish_aws_connection(access_key_id, secret_access_key)
      return unless access_key_id && secret_access_key

      AWS::S3::Base.establish_connection!(
        :access_key_id     => access_key_id,
        :secret_access_key => secret_access_key)
    end

  end
end
