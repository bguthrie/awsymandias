require 'rubygems'
require 'spec/rake/spectask'
require 'rake/gempackagetask'

Spec::Rake::SpecTask.new

gem_spec = eval(IO.read(File.join(File.dirname(__FILE__), "aws-sdb.gemspec")))

desc "Open an irb session preloaded with this library"
task :console do
  sh "irb -rubygems -I lib -r aws_sdb.rb"
end

Rake::GemPackageTask.new(gem_spec) do |pkg|
  pkg.gem_spec = gem_spec
end

task :install => [:package] do
  sh %{sudo gem install pkg/#{gem_spec.name}-#{gem_spec.version}}
end
