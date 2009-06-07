# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{awsymandias}
  s.version = "0.1.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Brian Guthrie"]
  s.date = %q{2009-06-07}
  s.description = %q{A library for helping you set up, track, and tear down complicated deployment configurations in Amazon EC2.}
  s.email = %q{btguthrie@gmail.com}
  s.extra_rdoc_files = [
    "README.rdoc"
  ]
  s.files = [
    ".gitignore",
     "README.rdoc",
     "Rakefile",
     "VERSION",
     "lib/awsymandias.rb",
     "spec/awsymandias_spec.rb"
  ]
  s.has_rdoc = true
  s.homepage = %q{http://github.com/bguthrie/awsymandias}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{A library for helping you set up, track, and tear down complicated deployment configurations in Amazon EC2.}
  s.test_files = [
    "spec/awsymandias_spec.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<activesupport>, [">= 2.3.0"])
      s.add_runtime_dependency(%q<activeresource>, [">= 2.3.0"])
      s.add_runtime_dependency(%q<hungryblank-aws-sdb>, [">= 0.4.0"])
      s.add_runtime_dependency(%q<grempe-amazon-ec2>, [">= 0.4.2"])
    else
      s.add_dependency(%q<activesupport>, [">= 2.3.0"])
      s.add_dependency(%q<activeresource>, [">= 2.3.0"])
      s.add_dependency(%q<hungryblank-aws-sdb>, [">= 0.4.0"])
      s.add_dependency(%q<grempe-amazon-ec2>, [">= 0.4.2"])
    end
  else
    s.add_dependency(%q<activesupport>, [">= 2.3.0"])
    s.add_dependency(%q<activeresource>, [">= 2.3.0"])
    s.add_dependency(%q<hungryblank-aws-sdb>, [">= 0.4.0"])
    s.add_dependency(%q<grempe-amazon-ec2>, [">= 0.4.2"])
  end
end
