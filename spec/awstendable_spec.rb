require 'rubygems'
require 'spec'
require File.dirname(__FILE__) + "/../lib/awstendable"

describe Awstendable::EC2::Instance do  
  describe "connection" do
    it "should configure an instance of EC2::Base" do
      Awstendable.access_key_id = "configured key"
      Awstendable.secret_access_key = "configured secret"
      
      ::EC2::Base.should_receive(:new).
        with(hash_including(:access_key_id => "configured key", :secret_access_key => "configured secret")).
        and_return(:a_connection)
      
      Awstendable::EC2.connection.should == :a_connection
    end    
  end
  
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
    
    it "should map camelized XML properties to Ruby-friendly underscored method names" do
      Awstendable::EC2.stub!(:connection).and_return stub("a connection", :describe_instances => DESCRIBE_INSTANCES_SINGLE_RESULT_RUNNING_XML)
      instance = Awstendable::EC2::Instance.find("an instance id")
      instance.image_id.should == "ami-dc789fb5"
      instance.key_name.should == "gsg-keypair"
      instance.instance_type.should == "m1.large"
      instance.placement.availability_zone.should == "us-east-1c"
    end
  end
  
  describe "to_params" do
    it "should be able to reproduce a reasonable set of its launch params as a hash" do
      Awstendable::EC2.stub!(:connection).and_return stub("a connection", :describe_instances => DESCRIBE_INSTANCES_SINGLE_RESULT_RUNNING_XML)
      Awstendable::EC2::Instance.find("an instance id").to_params.should == {
        :image_id => "ami-dc789fb5",
        :key_name => "gsg-keypair",
        :instance_type => "m1.large",
        :availability_zone => "us-east-1c"
      }
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
  Instance         = Awstendable::EC2::Instance
  
  class SimpleDBStub
    def initialize
      @store = {}
    end

    def list_domains
      [ @store.keys ]
    end

    def put_attributes(domain, name, attributes)
      @store[domain][name] = attributes
    end

    def get_attributes(domain, name)
      @store[domain][name]
    end
    
    def delete_attributes(domain, name)
      @store[domain][name] = nil
    end

    def create_domain(domain)
      @store[domain] = {}
    end
  end
  
  attr_accessor :simpledb
  
  def stub_instance(stubs={})
    Instance.new({:instance_id => "i-12345a3c"}.merge(stubs))
  end
  
  before :each do
    @simpledb = SimpleDBStub.new
    Awstendable::SimpleDB.stub!(:connection).and_return @simpledb
  end
    
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
    
  describe "launch" do
    it "should launch its roles when launched" do
      s = ApplicationStack.new("test") do |s| 
        s.role "db1",  :instance_type => Awstendable::EC2::InstanceTypes::C1_XLARGE
        s.role "app1", :instance_type => Awstendable::EC2::InstanceTypes::M1_LARGE
      end
    
      Instance.should_receive(:launch).with({ :instance_type => Awstendable::EC2::InstanceTypes::C1_XLARGE }).and_return(mock("instance1", :instance_id => "a"))
      Instance.should_receive(:launch).with({ :instance_type => Awstendable::EC2::InstanceTypes::M1_LARGE }).and_return(mock("instance2", :instance_id => "b"))
    
      s.launch
    end
    
    it "should set the getter for the particular instance to the return value of launching the instance" do      
      s = ApplicationStack.new("test") do |s| 
        s.role "db1",  :instance_type => Awstendable::EC2::InstanceTypes::C1_XLARGE
        s.role "app1", :instance_type => Awstendable::EC2::InstanceTypes::M1_LARGE
      end
      
      instances = [ stub_instance, stub_instance ]
      
      Instance.stub!(:launch).with({ :instance_type => Awstendable::EC2::InstanceTypes::C1_XLARGE }).and_return instances.first
      Instance.stub!(:launch).with({ :instance_type => Awstendable::EC2::InstanceTypes::M1_LARGE }).and_return instances.last
      
      s.db1.should be_nil
      s.app1.should be_nil
            
      s.launch
      
      s.db1.should == instances.first
      s.app1.should == instances.last
    end
    
    it "should store details about the newly launched instances" do
      Awstendable::EC2::Instance.stub!(:launch).and_return stub_instance(:instance_id => "abc123")
      Awstendable::EC2::ApplicationStack.new("test") do |s| 
        s.role "db1", :instance_type => Awstendable::EC2::InstanceTypes::C1_XLARGE
      end.launch
      
      simpledb.get_attributes(ApplicationStack::DEFAULT_SDB_DOMAIN, "test").should == { "db1" => "abc123" }
    end
  end
  
  describe "launched?" do    
    it "should be false initially" do
      s = ApplicationStack.new("test") {|s| s.role "db1", :instance_type => Awstendable::EC2::InstanceTypes::M1_LARGE}
      s.should_not be_launched
    end
    
    it "should be true if launched and instances are non-empty" do
      s = ApplicationStack.new("test") { |s| s.role "db1" }
      Awstendable::EC2::Instance.stub!(:launch).and_return stub_instance
      s.launch
      s.should be_launched
    end
    
    it "should attempt to determine whether or not it's been previously launched" do
      Awstendable::SimpleDB.put ApplicationStack::DEFAULT_SDB_DOMAIN, "test", "db1" => ["instance_id"]
      an_instance = stub_instance :instance_id => "instance_id"
      Instance.should_receive(:find).with(:all, :instance_ids => [ "instance_id" ]).and_return [ an_instance ]
      s = ApplicationStack.new("test") { |s| s.role "db1" }
      s.should be_launched
      s.db1.should == an_instance
    end
  end
  
  describe "running?" do
    it "should be false initially" do
      ApplicationStack.new("test") {|s| s.role "db1"}.should_not be_running
    end
    
    it "should be false if launched but all instances are pended" do
      Instance.stub!(:launch).and_return stub_instance(:instance_state => { :name => "pending" })
      ApplicationStack.new("test") {|s| s.role "db1"}.launch.should_not be_running
    end
    
    it "should be false if launched and some instances are pended" do
      s = ApplicationStack.new("test") do |s| 
        s.role "db1", :instance_type => Awstendable::EC2::InstanceTypes::C1_XLARGE
        s.role "app1", :instance_type => Awstendable::EC2::InstanceTypes::M1_LARGE
      end
      
      Instance.stub!(:launch).
        with({ :instance_type => Awstendable::EC2::InstanceTypes::C1_XLARGE }).
        and_return stub_instance(:instance_state => { :name => "pending" })
        
      Instance.stub!(:launch).
        with({ :instance_type => Awstendable::EC2::InstanceTypes::M1_LARGE }).
        and_return stub_instance(:instance_state => { :name => "running" })
        
      s.launch
      s.should_not be_running
    end
    
    it "should be true if launched and all instances are running" do
      s = ApplicationStack.new("test") do |s| 
        s.role "db1", :instance_type => Awstendable::EC2::InstanceTypes::C1_XLARGE
        s.role "app1", :instance_type => Awstendable::EC2::InstanceTypes::M1_LARGE
      end
      
      Instance.stub!(:launch).
        with({ :instance_type => Awstendable::EC2::InstanceTypes::C1_XLARGE }).
        and_return stub_instance(:instance_state => { :name => "running" })
        
      Instance.stub!(:launch).
        with({ :instance_type => Awstendable::EC2::InstanceTypes::M1_LARGE }).
        and_return stub_instance(:instance_state => { :name => "running" })
        
      s.launch
      s.should be_running
    end
  end
  
  describe "terminate!" do
    it "should not do anything if not running" do
      s = ApplicationStack.new("test") { |s| s.role "db1" }
      Awstendable::EC2.should_receive(:connection).never
      s.terminate!
    end
    
    it "should terminate all instances if running" do
      s = ApplicationStack.new("test") { |s| s.role "db1" }
      mock_instance = mock("an_instance", :instance_id => "i-foo")
      mock_instance.should_receive(:terminate!)
      Instance.stub!(:launch).and_return(mock_instance)
      s.launch
      s.terminate!      
    end
    
    it "should remove any stored role name mappings" do
      Awstendable::SimpleDB.put ApplicationStack::DEFAULT_SDB_DOMAIN, "test", "db1" => ["instance_id"]
      s = ApplicationStack.new("test") { |s| s.role "db1" }
      Instance.stub!(:launch).and_return stub('stub').as_null_object
      s.launch
      s.terminate!
      Awstendable::SimpleDB.get(ApplicationStack::DEFAULT_SDB_DOMAIN, "test").should be_blank
    end
  end
end

describe Awstendable::SimpleDB do
  describe "connection" do
    it "configure an instance of AwsSdb::Service" do
      Awstendable.access_key_id = "configured key"
      Awstendable.secret_access_key = "configured secret"
      
      ::AwsSdb::Service.should_receive(:new).
        with(hash_including(:access_key_id => "configured key", :secret_access_key => "configured secret")).
        and_return(:a_connection)
      
      Awstendable::SimpleDB.connection.should == :a_connection
    end
  end
end