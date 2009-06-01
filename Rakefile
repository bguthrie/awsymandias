require 'rubygems'
require 'spec/rake/spectask'
require 'rake/gempackagetask'

# task :spec
Spec::Rake::SpecTask.new

desc "Open an irb session preloaded with this library"
task :console do
  sh "irb -rubygems -I lib -r aws_sdb.rb"
end

task :default => [:spec]