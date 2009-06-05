require 'rubygems'
require 'spec/rake/spectask'
require 'rake/gempackagetask'

# task :spec
Spec::Rake::SpecTask.new do |t|
  t.rcov = true
  t.rcov_opts = ["--text-summary", "--include-file lib/awsymandias", "--exclude gems,spec"]
end

desc "Open an irb session preloaded with this library"
task :console do
  sh "irb -rubygems -I lib -r lib/awsymandias"
end

task :default => [:spec]