# Rack::S3

Serve files from an S3 bucket as if they were local assets similar to
Rack::Static. Stand up behind Rack::Thumb for fame and notoriety.


## Usage

    require 'myapp'
    require 'rack/thumb'
    require 'rack/s3'

    use Rack::Thumb
    use Rack::S3

    run MyApp.new


## Copyright

Copyright (c) 2011 Larry Marburger. See [LICENSE] for details.


[LICENSE]: http://github.com/lmarburger/rack-s3/blob/master/LICENSE
