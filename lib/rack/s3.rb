# frozen_string_literal: true

require "aws-sdk-s3"
require "rack"

# Serve static s3 content, like Rack::Files
class Rack::S3
  def initialize(url: nil, bucket: nil, prefix: nil, client: Aws::S3::Client.new)
    if url
      uri = URI.parse(url)
      raise "Not an S3 url" unless uri.scheme == "s3"
      bucket = uri.host
      prefix = uri.path.delete_prefix("/")
    end

    prefix = nil if prefix == "" || prefix == "/"

    @bucket = bucket
    @prefix = prefix
    @client = client
  end

  def call(env)
    request = Rack::Request.new(env)

    # Only allow GET
    return error(405, { "Allow" => "GET" }) unless request.get?

    # Don't allow odd encodings in paths
    path_info = Rack::Utils.unescape_path request.path_info
    return error(400) unless Rack::Utils.valid_path?(path_info)

    # Redirect when logical uri path ends with a slash, but not really
    # i.e. mount Rack::S3.new(...), at: "blah" # => /blah => /blah/
    if (path_info.nil? || path_info.empty? || path_info.end_with?("/")) && !request.fullpath.end_with?("/")
      return redirect(request.fullpath + "/")
    end

    # Rails routes with mount "/blah" => Rack::S3.new(...), and a request to
    # "/blah" produces a script_path of "/blah" and path_info of "/". If we
    # serve an index.html at that uri then relative references will not work.
    # So consult the request_path, if we can, to double check.
    if env["REQUEST_PATH"] && request.fullpath.end_with?("/") && !env["REQUEST_PATH"].end_with?("/")
      return redirect(request.fullpath)
    end

    # Reject any traversals, etc
    clean_path = Rack::Utils.clean_path_info(path_info)
    return error(400) unless clean_path == path_info

    key = path_info.delete_prefix("/")

    key = "#{@prefix}/#{key}" if @prefix

    # Basic index file support
    if key.empty? || key.end_with?("/")
      key << "index.html"
    end

    # It would be nice to only head the object if we need to (if modified
    # since, etc), but aws-sdk-s3 doesn't expose a nice way to get an object,
    # use its response headers, and then stream the body -- you can only
    # receive a response with a buffered body, or stream the body before
    # getting the headers.
    head = @client.head_object(bucket: @bucket, key: key)

    etag = head.etag
    if none_match = request.get_header("HTTP_IF_NONE_MATCH")
      return not_modified if none_match == etag
    end

    last_modified = head.last_modified.httpdate
    if modified_since = request.get_header("HTTP_IF_MODIFIED_SINCE")
      return not_modified if modified_since == last_modified
    end

    headers = {
      "Content-Length" => head.content_length.to_s,
      "Content-Type" => head.content_type,
      "ETag" => etag,
      "Last-Modified" => last_modified,
    }

    body = Enumerator.new do |enum|
      @client.get_object(bucket: @bucket, key: key) do |chunk|
        enum.yield chunk
      end
    end

    [200, headers, body]
  rescue Aws::S3::Errors::Forbidden
    error(403)
  rescue Aws::S3::Errors::NotFound
    error(404)
  end

  private

  def redirect(location)
    [302, { "Location" => location }, []]
  end

  def not_modified
    [304, {}, []]
  end

  def error(status, headers = {})
    body = Rack::Utils::HTTP_STATUS_CODES.fetch(status)

    headers = {
      "Content-Type" => "text/plain",
      "Content-Length" => body.size.to_s,
    }.merge!(headers)

    [status, headers, [body]]
  end
end
