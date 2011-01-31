# Rack::S3

**Rack::S3** is a middleware for serving assets from an S3 bucket. Why would you
want to bypass a perfectly good CDN? For stacking behind other middlewares, of
course! Drop it behind Rack::Thumb for dynamic thumbnails without the mess of
pregenerating.

For more information, see [http://lmarburger.github.com/rack-s3](http://lmarburger.github.com/rack-s3)
