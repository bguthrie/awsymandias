require 'rubygems'
require 'spec/rake/spectask'
require 'rake/gempackagetask'
require 'jeweler'


namespace :spec do

  desc "runs all the unit specs"
  Spec::Rake::SpecTask.new(:unit) do |t|
    t.rcov = true
    t.rcov_opts = ["--text-summary", "--include-file lib/awsymandias", "--exclude gems,spec"]
    t.spec_files = FileList['spec/unit/**/*_spec.rb']
  end

  desc "runs all the integration specs (requires AMAZON_ACCESS_KEY_ID and AMAZON_SECRET_ACCESS_KEY env variables to be set)"
  Spec::Rake::SpecTask.new(:integration) do |t|
    t.rcov = true
    t.rcov_opts = ["--text-summary", "--include-file lib/awsymandias", "--exclude gems,spec"]
    t.spec_files = FileList['spec/integration/**/*_spec.rb']
  end
  
end

desc "runs all the specs"
task :spec => [:'spec:unit', :'spec:integration']

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
