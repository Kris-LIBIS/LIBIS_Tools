require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'yard'

RSpec::Core::RakeTask.new

YARD::Rake::YardocTask.new do |t|
  t.files   = ['lib/**/*.rb']
end

task :default => :spec
