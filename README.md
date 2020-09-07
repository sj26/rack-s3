# Rack S3

Expose an [S3][s3] bucket prefix as a [Rack][rack] application with streaming.

  ![s3]: https://aws.amazon.com/s3
  ![rack]: https://github.com/rack/rack

## Usage

Specify an S3 URI to mount a bucket and optional prefix:

```ruby
# config.ru

run Rack::S3.new("s3://my-bucket/assets")
```

or, with options:

```ruby
# config.ru

run Rack::S3.new(bucket: "my-app", prefix: "assets", client: Aws::S3::Client.new(...))
```
