require 'bundler'
require 'rake/testtask'

Bundler::GemHelper.install_tasks

Rake::TestTask.new('test') do |t|
  t.libs << 'test'
  t.pattern = 'test/*_test.rb'
  t.verbose = true
end

desc 'Default: run tests'
task :default => 'test'

desc 'Generate documentation'
task :doc do
  sh 'rocco lib/rack/s3.rb && mv lib/rack/s3.html index.html'
end
