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
task :docs do
  sh 'docco lib/**/*.rb && mv docs/s3.html ../rack-s3-docs/index.html && mv docs/* ../rack-s3-docs/ && rm -rf docs'
end
