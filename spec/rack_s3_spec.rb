require "rack"
require "rack/s3"
require "rack/test"

RSpec.describe Rack::S3, vcr: true do
  include Rack::Test::Methods

  let(:s3) { Aws::S3::Client.new(endpoint: ENV.fetch("AWS_S3_ENDPOINT", "http://localhost:9000"), force_path_style: true) }

  let(:bucket) { ENV.fetch("BUCKET", "rack-s3-test") }

  before do
    s3.create_bucket(bucket: bucket)

    s3.put_object(bucket: bucket, key: "foo", content_type: "some/type", body: "bar")
    s3.put_object(bucket: bucket, key: "index.html", content_type: "text/html", body: "Hello <strong>world</strong>!")

    s3.put_object(bucket: bucket, key: "prefix/foo", content_type: "some/type", body: "prefixed")
    s3.put_object(bucket: bucket, key: "prefix/index.html", content_type: "text/html", body: "Hello <strong>prefixed</strong>!")
  end

  after do
    objects = s3.list_objects(bucket: bucket).contents
    if objects.any?
      s3.delete_objects(bucket: bucket, delete: { objects: objects.map { |object| { key: object.key } } })
    end

    s3.delete_bucket(bucket: bucket)
  end

  subject(:rack_s3) { Rack::S3.new(bucket: bucket, client: s3) }

  let(:app) { Rack::Builder.new(Rack::Lint.new(rack_s3)).to_app }

  it "proxies the contents given an matching path" do
    get "/foo"
    expect(last_response.status).to eq(200)
    expect(last_response.body).to eq("bar")
  end

  it "returns a 304 for a matching etag" do
    get "/foo", {}, { "HTTP_IF_NONE_MATCH" => "\"37b51d194a7513e45b56f6524f2d51f2\"" }
    expect(last_response.status).to eq(304)
    expect(last_response.body).to be_empty
  end

  it "returns a 304 for a matching last-modified" do
    get "/foo", {}, { "HTTP_IF_MODIFIED_SINCE" => s3.head_object(bucket: bucket, key: "foo").last_modified.httpdate }
    expect(last_response.status).to eq(304)
    expect(last_response.body).to be_empty
  end

  it "returns a 404 for a missing path" do
    get "/nope"
    expect(last_response.status).to eq(404)
    expect(last_response.body).to eq("Not Found")

    get "/really/nope"
    expect(last_response.status).to eq(404)
    expect(last_response.body).to eq("Not Found")
  end

  context "including a prefix" do
    let(:prefix) { "prefix" }
    subject(:rack_s3) { Rack::S3.new(bucket: bucket, prefix: prefix, client: s3) }

    it "proxies the contents given an matching path" do
      get "/foo"
      expect(last_response.status).to eq(200)
      expect(last_response.body).to eq("prefixed")
    end

    it "doesn't allow path traversal" do
      get "/../foo"
      expect(last_response.status).to eq(400)
      expect(last_response.body).to eq("Bad Request")
    end
  end

  context "constructed with an S3 URL" do
    let(:url) { "s3://#{bucket}" }

    subject(:rack_s3) { Rack::S3.new(url: url, client: s3) }

    it "proxies the contents given an matching path" do
      get "/foo"
      expect(last_response.status).to eq(200)
      expect(last_response.body).to eq("bar")
    end

    context "including a prefix" do
      let(:url) { "s3://#{bucket}/prefix" }

      it "proxies the contents given an matching path" do
        get "/foo"
        expect(last_response.status).to eq(200)
        expect(last_response.body).to eq("prefixed")
      end
    end
  end

  context "when mounted at a sub-path" do
    let(:app) { Rack::URLMap.new("/s3" => Rack::Lint.new(rack_s3)) }

    it "proxies the contents given an matching path" do
      get "/s3/foo"
      expect(last_response.status).to eq(200)
      expect(last_response.body).to eq("bar")
      expect(last_response.headers["Content-Length"].to_i).to eq(last_response.body.bytesize)
      expect(last_response.headers["Content-Type"]).to eq("some/type")
      expect(last_response.headers["Last-Modified"]).not_to be_empty
      expect(last_response.headers["ETag"]).to eq("\"37b51d194a7513e45b56f6524f2d51f2\"")
    end

    # Yes these are naive, but good enough to work in most situations in most browsers.

    it "returns a 304 for a matching etag" do
      get "/s3/foo", {}, { "HTTP_IF_NONE_MATCH" => "\"37b51d194a7513e45b56f6524f2d51f2\"" }
      expect(last_response.status).to eq(304)
      expect(last_response.body).to be_empty
    end

    it "returns a 304 for a matching last-modified" do
      get "/s3/foo", {}, { "HTTP_IF_MODIFIED_SINCE" => s3.head_object(bucket: bucket, key: "foo").last_modified.httpdate }
      expect(last_response.status).to eq(304)
      expect(last_response.body).to be_empty
    end

    it "returns a 404 for a missing path" do
      get "/s3/nope"
      expect(last_response.status).to eq(404)
      expect(last_response.body).to eq("Not Found")
    end

    it "redirects bare mounted path to a directory path" do
      get "/s3"
      expect(last_response.status).to eq(302)
      expect(last_response.headers["Location"]).to eq("/s3/")
    end

    it "redirects weird rails route mount situations" do
      get "/s3/", {}, { "REQUEST_PATH" => "/s3" }
      expect(last_response.status).to eq(302)
      expect(last_response.headers["Location"]).to eq("/s3/")
    end

    it "renders the index at the root path" do
      get "/s3/"
      expect(last_response.status).to eq(200)
      expect(last_response.headers["Content-Type"]).to eq("text/html")
      expect(last_response.body).to eq("Hello <strong>world</strong>!")
    end

    it "renders the index at the appropriate sub-path" do
      get "/s3/index.html"
      expect(last_response.status).to eq(200)
      expect(last_response.headers["Content-Type"]).to eq("text/html")
      expect(last_response.body).to eq("Hello <strong>world</strong>!")
    end
  end
end
