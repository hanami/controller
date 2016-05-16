require 'rake'
require 'rake/testtask'
require 'bundler/gem_tasks'

Rake::TestTask.new do |t|
  t.test_files = Dir['test/**/*_test.rb'].reject do |path|
    path.include?('isolation')
  end

  t.libs.push 'test'
end

namespace :test do
  task :coverage do
    ENV['COVERALL'] = 'true'
    Rake::Task['test'].invoke
  end
end

task default: :test
