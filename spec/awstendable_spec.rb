require 'rubygems'
require 'spec'
require File.dirname(__FILE__) + "/../lib/awstendable"

describe Awstendable::EC2::Instance do
  DESCRIBE_INSTANCES_NO_RESULTS_XML = {
    "requestId" => "7bca5c7c-1b51-473e-a930-611e55920e39",
    "xmlns"=>"http://ec2.amazonaws.com/doc/2008-12-01/",
    "reservationSet" => nil
  }
  
  DESCRIBE_INSTANCES_SINGLE_RESULT_PENDING_XML = {
    "requestId" => "7bca5c7c-1b51-473e-a930-611e55920e39",
    "xmlns"=>"http://ec2.amazonaws.com/doc/2008-12-01/",
    "reservationSet" => {
      "item" => [ {
        "reservationId" => "r-db68e3b2", 
        "requesterId" => "058890971305", 
        "ownerId" => "358110980006",
        "groupSet" => { "item" => [ { "groupId" => "default" } ] }, 
        "instancesSet" => { "item" => [ { 
          "productCodes" => nil, 
          "kernelId" => "aki-b51cf9dc", 
          "amiLaunchIndex" => "0", 
          "keyName" => "gsg-keypair", 
          "ramdiskId" => "ari-b31cf9da", 
          "launchTime" => "2009-04-20T01:30:35.000Z", 
          "instanceType" => "m1.large", 
          "imageId" => "ami-dc789fb5", 
          "privateDnsName" => nil, 
          "reason" => nil, 
          "placement" => { 
            "availabilityZone" => "us-east-1c" 
          }, 
          "dnsName" => nil, 
          "instanceId" => "i-25533a4c", 
          "instanceState" => {
            "name" => "pending", 
            "code"=>"0" 
          } } ] } } ] } 
  }
  
  DESCRIBE_INSTANCES_SINGLE_RESULT_RUNNING_XML = {
    "requestId" => "7bca5c7c-1b51-473e-a930-611e55920e39",
    "xmlns"=>"http://ec2.amazonaws.com/doc/2008-12-01/",
    "reservationSet" => {
      "item" => [ {
        "reservationId" => "r-db68e3b2", 
        "requesterId" => "058890971305", 
        "ownerId" => "358110980006",
        "groupSet" => { "item" => [ { "groupId" => "default" } ] }, 
        "instancesSet" => { "item" => [ { 
          "productCodes" => nil, 
          "kernelId" => "aki-b51cf9dc", 
          "amiLaunchIndex" => "0", 
          "keyName" => "gsg-keypair", 
          "ramdiskId" => "ari-b31cf9da", 
          "launchTime" => "2009-04-20T01:30:35.000Z", 
          "instanceType" => "m1.large", 
          "imageId" => "ami-dc789fb5", 
          "privateDnsName" => nil, 
          "reason" => nil, 
          "placement" => { 
            "availabilityZone" => "us-east-1c" 
          }, 
          "dnsName" => nil, 
          "instanceId" => "i-25533a4c", 
          "instanceState" => {
            "name" => "running", 
            "code"=>"0" 
          } } ] } } ] } 
  }
  
  DESCRIBE_INSTANCES_MULTIPLE_RESULTS_RUNNING_XML = {
    "requestId" => "7bca5c7c-1b51-473e-a930-611e55920e39",
    "xmlns"=>"http://ec2.amazonaws.com/doc/2008-12-01/",
    "reservationSet" => {
      "item" => [ {
        "reservationId" => "r-db68e3b2", 
        "requesterId" => "058890971305", 
        "ownerId" => "358110980006",
        "groupSet" => { "item" => [ { "groupId" => "default" } ] }, 
        "instancesSet" => { "item" => [ 
          {
            "productCodes" => nil, 
            "kernelId" => "aki-b51cf9dc", 
            "amiLaunchIndex" => "0", 
            "keyName" => "gsg-keypair", 
            "ramdiskId" => "ari-b31cf9da", 
            "launchTime" => "2009-04-20T01:30:35.000Z", 
            "instanceType" => "m1.large", 
            "imageId" => "ami-dc789fb5", 
            "privateDnsName" => nil, 
            "reason" => nil, 
            "placement" => { 
              "availabilityZone" => "us-east-1c" 
            }, 
            "dnsName" => nil, 
            "instanceId" => "i-25533a4c", 
            "instanceState" => {
              "name" => "running", 
              "code"=>"0" 
            } 
          },
          { 
            "productCodes" => nil, 
            "kernelId" => "aki-b51cf9dc", 
            "amiLaunchIndex" => "0", 
            "keyName" => "gsg-keypair", 
            "ramdiskId" => "ari-b31cf9da", 
            "launchTime" => "2009-04-20T01:30:35.000Z", 
            "instanceType" => "m1.large", 
            "imageId" => "ami-dc789fb5", 
            "privateDnsName" => nil, 
            "reason" => nil, 
            "placement" => { 
              "availabilityZone" => "us-east-1c" 
            }, 
            "dnsName" => nil, 
            "instanceId" => "i-738d77ab", 
            "instanceState" => {
              "name" => "pending", 
              "code"=>"0" 
            } 
          } ] } } ] } 
  }
  
  
  describe "find" do
    it "should raise ActiveResource::ResourceNotFound if the given instance ID is not found" do
      Awstendable::EC2.stub!(:connection).and_return stub("a connection", :describe_instances => DESCRIBE_INSTANCES_NO_RESULTS_XML)
      lambda do
        Awstendable::EC2::Instance.find("an instance id")
      end.should raise_error(ActiveResource::ResourceNotFound)
    end
    
    it "should return an object with the appropriate instance ID when an instance with the given ID is found" do
      Awstendable::EC2.stub!(:connection).and_return stub("a connection", :describe_instances => DESCRIBE_INSTANCES_SINGLE_RESULT_RUNNING_XML)
      Awstendable::EC2::Instance.find("an instance id").instance_id.should == "i-25533a4c"
    end
    
    it "should return more than one object if multiple IDs are requested" do
      Awstendable::EC2.stub!(:connection).and_return stub("a connection", :describe_instances => DESCRIBE_INSTANCES_MULTIPLE_RESULTS_RUNNING_XML)
      Awstendable::EC2::Instance.find(:all, :instance_ids => ["an instance id", "another id"]).map(&:instance_id).should == [ "i-25533a4c", "i-738d77ab" ]
    end
  end
  
  describe "running?" do        
    it "should return false if it contains an instances set with the given instance ID and its state is pending" do
      Awstendable::EC2.stub!(:connection).and_return stub("a connection", :describe_instances => DESCRIBE_INSTANCES_SINGLE_RESULT_PENDING_XML)
      Awstendable::EC2::Instance.find("an instance id").should_not be_running
    end
    
    it "should return true if it contains an instances set with the given instance ID and its state is running" do
      Awstendable::EC2.stub!(:connection).and_return stub("a connection", :describe_instances => DESCRIBE_INSTANCES_SINGLE_RESULT_RUNNING_XML)
      Awstendable::EC2::Instance.find("an instance id").should be_running
    end
  end
  
  describe "reload" do
    it "should reload an instance without replacing the object" do
      Awstendable::EC2.stub!(:connection).and_return stub("a connection", :describe_instances => DESCRIBE_INSTANCES_SINGLE_RESULT_PENDING_XML)
      instance = Awstendable::EC2::Instance.find("an instance id")
      instance.should_not be_running
      
      Awstendable::EC2.stub!(:connection).and_return stub("a connection", :describe_instances => DESCRIBE_INSTANCES_SINGLE_RESULT_RUNNING_XML)
      instance.reload.should be_running
    end    
  end
  
  RUN_INSTANCES_SINGLE_RESULT_XML = {
    "reservationId" => "r-276ee54e", 
    "groupSet" => { "item" => [ { 
      "groupId" => "default" 
    } ] }, 
    "requestId" => "a29db909-d8ef-4a14-80c1-c53157c0cd49", 
    "instancesSet" => { 
      "item" => [ { 
        "kernelId" => "aki-b51cf9dc", 
        "amiLaunchIndex" => "0", 
        "keyName" => "gsg-keypair", 
        "ramdiskId" => "ari-b31cf9da", 
        "launchTime" => "2009-04-20T01:39:12.000Z", 
        "instanceType" => "m1.large", 
        "imageId" => "ami-dc789fb5", 
        "privateDnsName" => nil, 
        "reason" => nil, 
        "placement" => { 
          "availabilityZone" => "us-east-1a"
        }, 
        "dnsName" => nil, 
        "instanceId" => "i-4b553c22", 
        "instanceState" => { 
          "name" => "pending", 
          "code" => "0" 
        } 
    } ] }, 
    "ownerId"=>"358110980006", 
    "xmlns"=>"http://ec2.amazonaws.com/doc/2008-12-01/"
  }
  
  describe "launch" do
    it "should launch a new instance with default values" do
      mock_connection = mock("a connection")
      mock_connection.should_receive(:run_instances).with(hash_including(
        :image_id => "an_id",
        :key_name => "gsg-keypair",
        :instance_type => Awstendable::EC2::InstanceTypes::M1_SMALL,
        :availability_zone => Awstendable::EC2::AvailabilityZones::US_EAST_1A
      )).and_return(RUN_INSTANCES_SINGLE_RESULT_XML)
      
      mock_connection.should_receive(:describe_instances).and_return(DESCRIBE_INSTANCES_SINGLE_RESULT_PENDING_XML)
      
      Awstendable::EC2.stub!(:connection).and_return mock_connection
      
      Awstendable::EC2::Instance.launch(
        :image_id => "an_id",
        :key_name => "gsg-keypair",
        :instance_type => Awstendable::EC2::InstanceTypes::M1_SMALL,
        :availability_zone => Awstendable::EC2::AvailabilityZones::US_EAST_1A        
      ).instance_id.should == "i-25533a4c"
    end
    
    it "should convert the user data it's given to a JSON hash" do
      mock_connection = mock("a connection")
      mock_connection.should_receive(:run_instances).with(hash_including(
        :user_data => "{\"foo\": \"bar\"}"
      )).and_return(RUN_INSTANCES_SINGLE_RESULT_XML)
      mock_connection.should_receive(:describe_instances).and_return(stub("response").as_null_object)
      
      Awstendable::EC2.stub!(:connection).and_return mock_connection
      Awstendable::EC2::Instance.launch(:user_data => { :foo => "bar" })
    end
  end
  
  TERMINATE_INSTANCES_SINGLE_RESULT_XML = {
    "requestId" => "c80c4770-eaab-45ce-972d-10e928e3f80c", 
    "instancesSet" => {
      "item" => [ { 
        "previousState" => { 
          "name" => "running", 
          "code"=>"16"
        }, 
        "shutdownState" => { 
          "name" => "shutting-down", 
          "code" => "32"
        }, 
        "instanceId" => "i-8c563ee5" } ] }, 
    "xmlns"=>"http://ec2.amazonaws.com/doc/2008-12-01/"
  }
  
  DESCRIBE_INSTANCES_SINGLE_RESULT_TERMINATED_XML = {
    "requestId" => "8b4fb505-de40-41b2-b18e-58f9bcba6f09", 
    "reservationSet" => { 
      "item" => [ { 
        "reservationId" => "r-75961c1c", 
        "groupSet" => { 
          "item" => [ { 
            "groupId" => "default" 
          } ]
        }, 
        "instancesSet" => {
          "item" => [ { 
            "productCodes" => nil, 
            "kernelId" => "aki-b51cf9dc", 
            "amiLaunchIndex" => "0", 
            "keyName" => "gsg-keypair", 
            "ramdiskId" => "ari-b31cf9da", 
            "launchTime" => "2009-04-22T00:54:06.000Z", 
            "instanceType" => "c1.xlarge", 
            "imageId" => "ami-dc789fb5", 
            "privateDnsName" => nil, 
            "reason" => "User initiated (2009-04-22 00:59:53 GMT)", 
            "placement" => { 
              "availabilityZone" => nil
            }, 
            "dnsName" => nil, 
            "instanceId" => "i-8c563ee5", 
            "instanceState" => { 
              "name" => "terminated", 
              "code" => "48"
            } 
          } ]
        }, 
        "ownerId" => "358110980006" 
      } ] }, 
    "xmlns"=>"http://ec2.amazonaws.com/doc/2008-12-01/"
  }
  
  describe "terminate!" do
    it "should terminate a running instance" do
      mock_connection = mock("a connection")
      mock_connection.should_receive(:describe_instances).and_return(
        DESCRIBE_INSTANCES_SINGLE_RESULT_RUNNING_XML,
        DESCRIBE_INSTANCES_SINGLE_RESULT_TERMINATED_XML
      )
      mock_connection.should_receive(:terminate_instances).and_return(
        TERMINATE_INSTANCES_SINGLE_RESULT_XML
      )
      
      Awstendable::EC2.stub!(:connection).and_return mock_connection
      
      instance = Awstendable::EC2::Instance.find("a result id")
      instance.should be_running
      instance.terminate!
      instance.should_not be_running
      instance.should be_terminated
    end
  end
end

describe Awstendable::EC2::ApplicationStack do
  ApplicationStack = Awstendable::EC2::ApplicationStack
  
  it "should have a name" do
    ApplicationStack.new("foo").name.should == "foo"
  end
  
  describe "roles" do
    it "should be empty by default" do
      ApplicationStack.new("foo").roles.should be_empty
    end
    
    it "should be settable through the initializer" do
      stack = ApplicationStack.new("foo", :roles => { :app1 => {} })
      stack.roles[:app1].should == {}
    end
  end
  
  describe "role" do
    it "should allow the definition of a basic, empty role" do
      stack = ApplicationStack.new("foo") do |s|
        s.role :app1
      end
      stack.roles[:app1].should == {}
    end
    
    it "should use the parameters given to the role definition" do
      stack = ApplicationStack.new("foo") do |s|
        s.role :app1, :foo => "bar"
      end
      stack.roles[:app1].should == { :foo => "bar" }
    end
    
    it "should allow for the creation of multiple roles" do
      stack = ApplicationStack.new("foo") do |s|
        s.role :app1, :foo => "bar"
        s.role :app2, :foo => "baz"
      end
      stack.roles[:app1].should == { :foo => "bar" }
      stack.roles[:app2].should == { :foo => "baz" }
    end
    
    it "should map multiple roles to the same set of parameters" do
      stack = ApplicationStack.new("foo") do |s|
        s.role :app1, :app2, :foo => "bar"
      end
      stack.roles[:app1].should == { :foo => "bar" }
      stack.roles[:app2].should == { :foo => "bar" }
    end
    
    it "should create an accessor mapped to the new role, nil by default" do
      stack = ApplicationStack.new("foo") do |s|
        s.role :app1, :foo => "bar"
      end
      stack.app1.should be_nil
    end
  end
  
  describe "sdb_domain" do
    it "should map to ApplicationStack::DEFAULT_SDB_DOMAIN upon creation" do
      ApplicationStack.new("foo").sdb_domain.should == ApplicationStack::DEFAULT_SDB_DOMAIN
    end
    
    it "should be configurable" do
      ApplicationStack.new("foo", :sdb_domain => "a domain").sdb_domain.should == "a domain"
    end
  end
    
  # before :each do
  #   stub_connection = stub!("foo")
  #   stub_connection.stub!(:put_attributes)
  #   stub_connection.stub!(:delete_attributes)
  #   stub_connection.stub!(:get_attributes).and_return({})
  #   AWS::SimpleDB.stub!(:connection).and_return stub_connection
  # end
  # 
  # def stub_instance(stubs={})
  #   AWS::EC2::Instance.new(stubs.merge(:instance_id => "i-12345a3c"))
  # end
  # 
  # describe "name" do
  #   it "should allow you to set a name" do
  #     AWS::EC2::ApplicationStack.new(:name => "test").name.should == "test"
  #   end
  # end
  # 
  # describe "role" do
  #   it "should define a simple role" do
  #     s = AWS::EC2::ApplicationStack.new {|s| s.role "db1", :instance_type => AWS::EC2::InstanceTypes::M1_LARGE}
  #     s.roles["db1"][:instance_type].should == AWS::EC2::InstanceTypes::M1_LARGE
  #   end
  #   
  #   it "should define a getter for each role" do
  #     s = AWS::EC2::ApplicationStack.new {|s| s.role "db1", :instance_type => AWS::EC2::InstanceTypes::M1_LARGE}
  #     s.db1.should be_nil
  #   end
  # end
  #   
  # describe "launch" do    
  #   it "should launch its roles when launched" do
  #     s = AWS::EC2::ApplicationStack.new do |s| 
  #       s.role "db1", :instance_type => AWS::EC2::InstanceTypes::C1_XLARGE
  #       s.role "app1", :instance_type => AWS::EC2::InstanceTypes::M1_LARGE
  #     end
  #   
  #     AWS::EC2::Instance.should_receive(:launch).with({ :instance_type => AWS::EC2::InstanceTypes::C1_XLARGE }).and_return(mock("instance1", :instance_id => "a"))
  #     AWS::EC2::Instance.should_receive(:launch).with({ :instance_type => AWS::EC2::InstanceTypes::M1_LARGE }).and_return(mock("instance2", :instance_id => "b"))
  #   
  #     s.launch
  #   end
  #   
  #   it "should set the getter for the particular instance to the return value of launching the instance" do      
  #     s = AWS::EC2::ApplicationStack.new do |s| 
  #       s.role "db1", :instance_type => AWS::EC2::InstanceTypes::C1_XLARGE
  #       s.role "app1", :instance_type => AWS::EC2::InstanceTypes::M1_LARGE
  #     end
  #     
  #     instances = [ stub_instance, stub_instance ]
  #     
  #     AWS::EC2::Instance.stub!(:launch).with({ :instance_type => AWS::EC2::InstanceTypes::C1_XLARGE }).and_return instances.first
  #     AWS::EC2::Instance.stub!(:launch).with({ :instance_type => AWS::EC2::InstanceTypes::M1_LARGE }).and_return instances.last
  #     
  #     s.db1.should be_nil
  #     s.app1.should be_nil
  #           
  #     s.launch
  #     
  #     s.db1.should == instances.first
  #     s.app1.should == instances.last
  #   end
  # end
  # 
  # describe "launched?" do    
  #   it "should be false initially" do
  #     s = AWS::EC2::ApplicationStack.new {|s| s.role "db1", :instance_type => AWS::EC2::InstanceTypes::M1_LARGE}
  #     s.should_not be_launched
  #   end
  #   
  #   it "should be true if launched and instances are non-empty" do
  #     s = AWS::EC2::ApplicationStack.new {|s| s.role "db1", :instance_type => AWS::EC2::InstanceTypes::M1_LARGE}
  #     AWS::EC2::Instance.stub!(:launch).and_return stub_instance
  #     s.launch
  #     s.should be_launched
  #   end
  # end
  # 
  # describe "running?" do
  #   it "should be false initially" do
  #     s = AWS::EC2::ApplicationStack.new {|s| s.role "db1", :instance_type => AWS::EC2::InstanceTypes::M1_LARGE}
  #     s.should_not be_running
  #   end
  #   
  #   it "should be false if launched but all instances are pended" do
  #     s = AWS::EC2::ApplicationStack.new {|s| s.role "db1", :instance_type => AWS::EC2::InstanceTypes::M1_LARGE}
  #     AWS::EC2::Instance.stub!(:launch).and_return stub_instance(:instance_state => { :name => "pending" })
  #     s.launch
  #     s.should_not be_running
  #   end
  #   
  #   it "should be false if launched and some instances are pended" do
  #     s = AWS::EC2::ApplicationStack.new do |s| 
  #       s.role "db1", :instance_type => AWS::EC2::InstanceTypes::C1_XLARGE
  #       s.role "app1", :instance_type => AWS::EC2::InstanceTypes::M1_LARGE
  #     end
  #     
  #     AWS::EC2::Instance.stub!(:launch).
  #       with({ :instance_type => AWS::EC2::InstanceTypes::C1_XLARGE }).
  #       and_return stub_instance(:instance_state => { :name => "pending" })
  #       
  #     AWS::EC2::Instance.stub!(:launch).
  #       with({ :instance_type => AWS::EC2::InstanceTypes::M1_LARGE }).
  #       and_return stub_instance(:instance_state => { :name => "running" })
  #       
  #     s.launch
  #     s.should_not be_running
  #   end
  #   
  #   it "should be true if launched and all instances are running" do
  #     s = AWS::EC2::ApplicationStack.new do |s| 
  #       s.role "db1", :instance_type => AWS::EC2::InstanceTypes::C1_XLARGE
  #       s.role "app1", :instance_type => AWS::EC2::InstanceTypes::M1_LARGE
  #     end
  #     
  #     AWS::EC2::Instance.stub!(:launch).
  #       with({ :instance_type => AWS::EC2::InstanceTypes::C1_XLARGE }).
  #       and_return stub_instance(:instance_state => { :name => "running" })
  #       
  #     AWS::EC2::Instance.stub!(:launch).
  #       with({ :instance_type => AWS::EC2::InstanceTypes::M1_LARGE }).
  #       and_return stub_instance(:instance_state => { :name => "running" })
  #       
  #     s.launch
  #     s.should be_running
  #   end
  # end
  # 
  # describe "terminate!" do
  #   it "should not do anything if not running" do
  #     s = AWS::EC2::ApplicationStack.new {|s| s.role "db1", :instance_type => AWS::EC2::InstanceTypes::M1_LARGE}
  #     AWS::EC2.should_receive(:connection).never
  #     s.terminate!
  #   end
  #   
  #   it "should terminate all instances if running" do
  #     s = AWS::EC2::ApplicationStack.new {|s| s.role "db1", :instance_type => AWS::EC2::InstanceTypes::M1_LARGE}
  #     mock_instance = mock("an_instance", :instance_id => "i-foo")
  #     mock_instance.should_receive(:terminate!)
  #     AWS::EC2::Instance.stub!(:launch).and_return(mock_instance)
  #     s.launch
  #     s.terminate!      
  #   end
  # end
end
