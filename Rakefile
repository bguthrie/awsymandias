require 'rubygems'
require 'spec/rake/spectask'
require 'rake/gempackagetask'
require 'jeweler'

# task :spec
Spec::Rake::SpecTask.new do |t|
  t.rcov = true
  t.rcov_opts = ["--text-summary", "--include-file lib/awsymandias", "--exclude gems,spec"]
end

task :default => [:spec]

desc "Open an irb session preloaded with this library"
task :console do
  sh "irb -rubygems -I lib -r awsymandias"
end

Jeweler::Tasks.new do |s|
  s.name = "awsymandias"
  s.summary = "A library for helping you set up, track, and tear down complicated deployment configurations in Amazon EC2."
  s.email = "btguthrie@gmail.com"
  s.homepage = "http://github.com/bguthrie/awsymandias"
  s.description = "A library for helping you set up, track, and tear down complicated deployment configurations in Amazon EC2."
  s.authors = ["Brian Guthrie"]
  
  s.add_dependency 'activesupport', '>= 2.3.0'
  s.add_dependency 'activeresource', '>= 2.3.0'
  s.add_dependency 'grempe-amazon-ec2', '>= 0.4.2'
  s.add_dependency 'money', '>= 2.1.3'
end
