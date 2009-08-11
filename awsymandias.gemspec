# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{awsymandias}
  s.version = "0.3.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Brian Guthrie"]
  s.date = %q{2009-08-11}
  s.description = %q{A library for helping you set up, track, and tear down complicated deployment configurations in Amazon EC2.}
  s.email = %q{btguthrie@gmail.com}
  s.extra_rdoc_files = [
    "README.rdoc"
  ]
  s.files = [
    ".gitignore",
     ".specification",
     "README.rdoc",
     "Rakefile",
     "VERSION",
     "awsymandias.gemspec",
     "lib/awsymandias.rb",
     "lib/awsymandias/addons/right_elb_interface.rb",
     "lib/awsymandias/ec2.rb",
     "lib/awsymandias/ec2/application_stack.rb",
     "lib/awsymandias/extensions/class_extension.rb",
     "lib/awsymandias/extensions/net_http_extension.rb",
     "lib/awsymandias/instance.rb",
     "lib/awsymandias/load_balancer.rb",
     "lib/awsymandias/right_aws.rb",
     "lib/awsymandias/right_elb.rb",
     "lib/awsymandias/simple_db.rb",
     "lib/awsymandias/snapshot.rb",
     "lib/awsymandias/stack_definition.rb",
     "lib/awsymandias/volume.rb",
     "spec/integration/instance_spec.rb",
     "spec/unit/addons/right_elb_interface_spec.rb",
     "spec/unit/awsymandias_spec.rb",
     "spec/unit/ec2/application_stack_spec.rb",
     "spec/unit/instance_spec.rb",
     "spec/unit/load_balancer_spec.rb",
     "spec/unit/right_aws_spec.rb",
     "spec/unit/simple_db_spec.rb",
     "spec/unit/snapshot_spec.rb",
     "spec/unit/stack_definition_spec.rb",
     "tags"
  ]
  s.has_rdoc = true
  s.homepage = %q{http://github.com/bguthrie/awsymandias}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{A library for helping you set up, track, and tear down complicated deployment configurations in Amazon EC2.}
  s.test_files = [
    "spec/integration/instance_spec.rb",
     "spec/unit/addons/right_elb_interface_spec.rb",
     "spec/unit/awsymandias_spec.rb",
     "spec/unit/ec2/application_stack_spec.rb",
     "spec/unit/instance_spec.rb",
     "spec/unit/load_balancer_spec.rb",
     "spec/unit/right_aws_spec.rb",
     "spec/unit/simple_db_spec.rb",
     "spec/unit/snapshot_spec.rb",
     "spec/unit/stack_definition_spec.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<activesupport>, [">= 2.3.0"])
      s.add_runtime_dependency(%q<activeresource>, [">= 2.3.0"])
      s.add_runtime_dependency(%q<grempe-amazon-ec2>, [">= 0.4.2"])
      s.add_runtime_dependency(%q<money>, [">= 2.1.3"])
    else
      s.add_dependency(%q<activesupport>, [">= 2.3.0"])
      s.add_dependency(%q<activeresource>, [">= 2.3.0"])
      s.add_dependency(%q<grempe-amazon-ec2>, [">= 0.4.2"])
      s.add_dependency(%q<money>, [">= 2.1.3"])
    end
  else
    s.add_dependency(%q<activesupport>, [">= 2.3.0"])
    s.add_dependency(%q<activeresource>, [">= 2.3.0"])
    s.add_dependency(%q<grempe-amazon-ec2>, [">= 0.4.2"])
    s.add_dependency(%q<money>, [">= 2.1.3"])
  end
end
