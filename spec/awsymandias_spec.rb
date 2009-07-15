require 'rubygems'
require 'spec'
require File.dirname(__FILE__) + "/../lib/awsymandias"

describe Awsymandias do
  describe Awsymandias::SimpleDB do
    describe "connection" do
      it "configure an instance of AwsSdb::Service" do
        Awsymandias.access_key_id = "configured key"
        Awsymandias.secret_access_key = "configured secret"
      
        ::AwsSdb::Service.should_receive(:new).
          with(hash_including(:access_key_id => "configured key", :secret_access_key => "configured secret")).
          and_return(:a_connection)
      
        Awsymandias::SimpleDB.connection.should == :a_connection
      end
    end
  end
  
  describe Awsymandias::EC2 do    
    def stub_connection_with(return_value)
      Awsymandias::EC2.stub!(:connection).and_return stub("a connection", :describe_instances => return_value)
    end
    
    def zero_dollars
      Money.new(0)
    end
    
    describe "connection" do
      it "should configure an instance of EC2::Base" do
        Awsymandias.access_key_id = "configured key"
        Awsymandias.secret_access_key = "configured secret"

        ::EC2::Base.should_receive(:new).
          with(hash_including(:access_key_id => "configured key", :secret_access_key => "configured secret")).
          and_return(:a_connection)

        Awsymandias::EC2.connection.should == :a_connection
      end    
    end
    
    describe Instance = Awsymandias::EC2::Instance do
    
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
              "kernelId" => "aki-some-kernel", 
              "amiLaunchIndex" => "0", 
              "keyName" => "gsg-keypair", 
              "ramdiskId" => "ari-b31cf9da", 
              "launchTime" => "2009-04-20T01:30:35.000Z", 
              "instanceType" => "m1.large", 
              "imageId" => "ami-some-image", 
              "privateDnsName" => nil, 
              "reason" => nil, 
              "placement" => { 
                "availabilityZone" => "us-east-1c" 
              }, 
              "dnsName" => nil, 
              "instanceId" => "i-some-instance", 
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
              "kernelId" => "aki-some-kernel", 
              "amiLaunchIndex" => "0", 
              "keyName" => "gsg-keypair", 
              "ramdiskId" => "ari-b31cf9da", 
              "launchTime" => "2009-04-20T01:30:35.000Z", 
              "instanceType" => "m1.large", 
              "imageId" => "ami-some-image", 
              "privateDnsName" => "ip-10-244-226-239.ec2.internal", 
              "reason" => nil, 
              "placement" => { 
                "availabilityZone" => "us-east-1c" 
              }, 
              "dnsName" => "ec2-174-129-118-52.compute-1.amazonaws.com", 
              "instanceId" => "i-some-instance", 
              "instanceState" => {
                "name" => "running", 
                "code"=>"0" 
              } } ] } } ] } 
      }
  
      DESCRIBE_INSTANCES_MULTIPLE_RESULTS_RUNNING_XML = {
        "requestId" => "7bca5c7c-1b51-473e-a930-611e55920e39",
        "xmlns"=>"http://ec2.amazonaws.com/doc/2008-12-01/",
        "reservationSet" => {
          "item" => [ 
            { "reservationId"=>"r-5b226e32",
              "ownerId"=>"423319072129",
              "groupSet" => { "item" => [ {"groupId"=>"default" } ] },
              "instancesSet" => { "item" => [
                 { "productCodes"=>nil,
                   "kernelId"=>"aki-some-kernel",
                   "amiLaunchIndex"=>"0",
                   "ramdiskId"=>"ari-b31cf9da",
                   "launchTime"=>"2009-07-14T17:47:33.000Z",
                   "instanceType"=>"c1.xlarge",
                   "imageId"=>"ami-some-other-image",
                   "privateDnsName"=>nil,
                   "reason"=>nil,
                   "placement" => {
                     "availabilityZone"=>"us-east-1b"
                   },
                   "dnsName" => nil,
                   "instanceId"=>"i-some-other-instance",
                   "instanceState" => { 
                     "name"=>"running", 
                     "code"=>"16",
                    }
                  }
                ] } },
            { "reservationId" => "r-db68e3b2", 
              "requesterId" => "058890971305", 
              "ownerId" => "358110980006",
              "groupSet" => { "item" => [ { "groupId" => "default" } ] }, 
              "instancesSet" => { "item" => [ 
                { "productCodes" => nil, 
                  "kernelId" => "aki-some-kernel", 
                  "amiLaunchIndex" => "0", 
                  "keyName" => "gsg-keypair", 
                  "ramdiskId" => "ari-b31cf9da", 
                  "launchTime" => "2009-04-20T01:30:35.000Z", 
                  "instanceType" => "m1.large", 
                  "imageId" => "ami-some-image", 
                  "privateDnsName" => nil, 
                  "reason" => nil, 
                  "placement" => { 
                    "availabilityZone" => "us-east-1c" 
                  }, 
                  "dnsName" => nil, 
                  "instanceId" => "i-some-instance", 
                  "instanceState" => {
                    "name" => "running", 
                    "code"=>"0" 
                  } },
                { "productCodes" => nil, 
                  "kernelId" => "aki-some-kernel", 
                  "amiLaunchIndex" => "0", 
                  "keyName" => "gsg-keypair", 
                  "ramdiskId" => "ari-b31cf9da", 
                  "launchTime" => "2009-04-20T01:30:35.000Z", 
                  "instanceType" => "m1.large", 
                  "imageId" => "ami-some-image", 
                  "privateDnsName" => nil, 
                  "reason" => nil, 
                  "placement" => { 
                    "availabilityZone" => "us-east-1c" 
                  }, 
                  "dnsName" => nil, 
                  "instanceId" => "i-another-instance", 
                  "instanceState" => {
                    "name" => "pending", 
                    "code"=>"0" 
                  } 
                } ] } }
              ]
            } 
          }
  
      RUN_INSTANCES_SINGLE_RESULT_XML = {
        "reservationId" => "r-276ee54e", 
        "groupSet" => { "item" => [ { 
          "groupId" => "default" 
        } ] }, 
        "requestId" => "a29db909-d8ef-4a14-80c1-c53157c0cd49", 
        "instancesSet" => { 
          "item" => [ { 
            "kernelId" => "aki-some-kernel", 
            "amiLaunchIndex" => "0", 
            "keyName" => "gsg-keypair", 
            "ramdiskId" => "ari-b31cf9da", 
            "launchTime" => "2009-04-20T01:39:12.000Z", 
            "instanceType" => "m1.large", 
            "imageId" => "ami-some-image", 
            "privateDnsName" => nil, 
            "reason" => nil, 
            "placement" => { 
              "availabilityZone" => "us-east-1a"
            }, 
            "dnsName" => nil, 
            "instanceId" => "i-some-instance", 
            "instanceState" => { 
              "name" => "pending", 
              "code" => "0" 
            } 
        } ] }, 
        "ownerId"=>"358110980006", 
        "xmlns"=>"http://ec2.amazonaws.com/doc/2008-12-01/"
      }
  
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
            "instanceId" => "i-some-instance" } ] }, 
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
                "kernelId" => "aki-some-kernel", 
                "amiLaunchIndex" => "0", 
                "keyName" => "gsg-keypair", 
                "ramdiskId" => "ari-b31cf9da", 
                "launchTime" => "2009-04-22T00:54:06.000Z", 
                "instanceType" => "c1.xlarge", 
                "imageId" => "ami-some-image", 
                "privateDnsName" => nil, 
                "reason" => "User initiated (2009-04-22 00:59:53 GMT)", 
                "placement" => { 
                  "availabilityZone" => nil
                }, 
                "dnsName" => nil, 
                "instanceId" => "i-some-instance", 
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
    
      describe "find" do
        it "should raise ActiveResource::ResourceNotFound if the given instance ID is not found" do
          stub_connection_with DESCRIBE_INSTANCES_NO_RESULTS_XML
          lambda do
            Instance.find("i-some-instance")
          end.should raise_error(ActiveResource::ResourceNotFound)
        end
    
        it "should return an object with the appropriate instance ID when an instance with the given ID is found" do
          stub_connection_with DESCRIBE_INSTANCES_SINGLE_RESULT_RUNNING_XML
          Instance.find("i-some-instance").instance_id.should == "i-some-instance"
        end
    
        it "should return more than one object if multiple IDs are requested" do
          stub_connection_with DESCRIBE_INSTANCES_MULTIPLE_RESULTS_RUNNING_XML
          Instance.find(:all, :instance_ids => ["i-some-other-instance", "i-some-instance", "i-another-instance"]).map do |instance|
            instance.instance_id
          end.should == ["i-some-other-instance", "i-some-instance", "i-another-instance"]
        end
    
        it "should map camelized XML properties to Ruby-friendly underscored method names" do
          stub_connection_with DESCRIBE_INSTANCES_SINGLE_RESULT_RUNNING_XML
          instance = Instance.find("i-some-instance")
          instance.image_id.should == "ami-some-image"
          instance.key_name.should == "gsg-keypair"
          instance.instance_type.should == Awsymandias::EC2.instance_types["m1.large"]
          instance.placement.availability_zone.should == "us-east-1c"
        end
      end
  
      describe "to_params" do
        it "should be able to reproduce a reasonable set of its launch params as a hash" do
          stub_connection_with DESCRIBE_INSTANCES_SINGLE_RESULT_RUNNING_XML
          Instance.find("i-some-instance").to_params.should == {
            :image_id => "ami-some-image",
            :key_name => "gsg-keypair",
            :instance_type => Awsymandias::EC2.instance_types["m1.large"],
            :availability_zone => "us-east-1c"
          }
        end
      end
  
      describe "running?" do        
        it "should return false if it contains an instances set with the given instance ID and its state is pending" do
          stub_connection_with DESCRIBE_INSTANCES_SINGLE_RESULT_PENDING_XML
          Instance.find("i-some-instance").should_not be_running
        end
    
        it "should return true if it contains an instances set with the given instance ID and its state is running" do
          stub_connection_with DESCRIBE_INSTANCES_SINGLE_RESULT_RUNNING_XML
          Instance.find("i-some-instance").should be_running
        end
      end
  
      describe "reload" do
        it "should reload an instance without replacing the object" do
          stub_connection_with DESCRIBE_INSTANCES_SINGLE_RESULT_PENDING_XML
          instance = Instance.find("i-some-instance")
          instance.should_not be_running
      
          stub_connection_with DESCRIBE_INSTANCES_SINGLE_RESULT_RUNNING_XML
          instance.reload.should be_running
        end    
      end
    
      describe "launch" do
        it "should launch a new instance given some values" do
          mock_connection = mock("a connection")
          mock_connection.should_receive(:run_instances).with(hash_including(
            :image_id => "an_id",
            :key_name => "gsg-keypair",
            :instance_type => "m1.small",
            :availability_zone => Awsymandias::EC2::AvailabilityZones::US_EAST_1A
          )).and_return(RUN_INSTANCES_SINGLE_RESULT_XML)
      
          mock_connection.should_receive(:describe_instances).and_return(DESCRIBE_INSTANCES_SINGLE_RESULT_PENDING_XML)
      
          Awsymandias::EC2.stub!(:connection).and_return mock_connection
      
          Awsymandias::EC2::Instance.launch(
            :image_id => "an_id",
            :key_name => "gsg-keypair",
            :instance_type => Awsymandias::EC2::InstanceTypes::M1_SMALL,
            :availability_zone => Awsymandias::EC2::AvailabilityZones::US_EAST_1A        
          ).instance_id.should == "i-some-instance"
        end
    
        it "should convert the instance type it's given to a string as needed" do
          mock_connection = mock("a connection")
          mock_connection.should_receive(:run_instances).with(hash_including(
            :instance_type => "m1.small"
          )).and_return(RUN_INSTANCES_SINGLE_RESULT_XML)
          mock_connection.should_receive(:describe_instances).and_return(stub("response").as_null_object)
          Awsymandias::EC2.stub!(:connection).and_return mock_connection
          
          Awsymandias::EC2::Instance.launch(:instance_type => Awsymandias::EC2::InstanceTypes::M1_SMALL)
        end
      end
    
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
      
          Awsymandias::EC2.stub!(:connection).and_return mock_connection
      
          instance = Awsymandias::EC2::Instance.find("a result id")
          instance.should be_running
          instance.terminate!
          instance.should_not be_running
          instance.should be_terminated
        end
      end
    
      describe "instance_type" do
        it "should return its instance_type attribute as an InstanceType object" do
          stub_connection_with DESCRIBE_INSTANCES_SINGLE_RESULT_RUNNING_XML
          Instance.find("i-some-instance").instance_type.should == Awsymandias::EC2::InstanceTypes::M1_LARGE
        end
      end
  
      describe "launch_time" do
        it "should return its launch_time attribute as an instance of Time" do
          stub_connection_with DESCRIBE_INSTANCES_SINGLE_RESULT_PENDING_XML
          Awsymandias::EC2::Instance.find("i-some-instance").launch_time.should == Time.parse("2009-04-20T01:30:35.000Z")
        end
      end
  
      describe "uptime" do
        it "should be zero seconds if it is not yet running" do
          stub_connection_with DESCRIBE_INSTANCES_SINGLE_RESULT_PENDING_XML
          Awsymandias::EC2::Instance.find("i-some-instance").uptime.should == 0.seconds
        end
        
        it "should calculate the uptime of a running instance in terms of its launch time" do
          time_now = Time.now
          Time.stub!(:now).and_return time_now
          stub_connection_with DESCRIBE_INSTANCES_SINGLE_RESULT_RUNNING_XML
          instance = Awsymandias::EC2::Instance.find("i-some-instance")
          instance.uptime.should == (time_now - instance.launch_time)
        end
      end

      describe "public_dns" do
        it "should return the public dns from the xml" do
          stub_connection_with DESCRIBE_INSTANCES_SINGLE_RESULT_RUNNING_XML 
          Awsymandias::EC2::Instance.find("i-some-instance").public_dns.should == "ec2-174-129-118-52.compute-1.amazonaws.com"
        end
      end
      
      describe "public_ip" do
        it "should parse the public dns to get the public IP address" do
          stub_connection_with DESCRIBE_INSTANCES_SINGLE_RESULT_RUNNING_XML 
          Awsymandias::EC2::Instance.find("i-some-instance").public_ip.should == "174.129.118.52"
        end
      end

      describe "private_dns" do
        it "should return the private dns from the xml" do
          stub_connection_with DESCRIBE_INSTANCES_SINGLE_RESULT_RUNNING_XML 
          Awsymandias::EC2::Instance.find("i-some-instance").private_dns.should == "ip-10-244-226-239.ec2.internal"
        end
      end

      describe "private_ip" do
        it "should parse the private dns to get the private IP address" do
          stub_connection_with DESCRIBE_INSTANCES_SINGLE_RESULT_RUNNING_XML 
          Awsymandias::EC2::Instance.find("i-some-instance").private_ip.should == "10.244.226.239"
        end
      end
  
      describe "running_cost" do
        it "should be zero if the instance has not yet been launched" do
          stub_connection_with DESCRIBE_INSTANCES_SINGLE_RESULT_PENDING_XML
          Awsymandias::EC2::Instance.find("i-some-instance").running_cost.should == zero_dollars
        end
        
        it "should be a single increment if the instance was launched 5 minutes ago" do
          stub_connection_with DESCRIBE_INSTANCES_SINGLE_RESULT_RUNNING_XML
          instance = Awsymandias::EC2::Instance.find("i-some-instance")
          instance.attributes['launch_time'] = 5.minutes.ago.to_s
          expected_cost = instance.instance_type.price_per_hour
          instance.running_cost.should == expected_cost
        end
        
        it "should be a single increment if the instance was launched 59 minutes ago" do
          stub_connection_with DESCRIBE_INSTANCES_SINGLE_RESULT_RUNNING_XML
          instance = Awsymandias::EC2::Instance.find("i-some-instance")
          instance.attributes['launch_time'] = 59.minutes.ago.to_s
          expected_cost = instance.instance_type.price_per_hour
          instance.running_cost.should == expected_cost
        end
        
        it "should be two increments if the instance was launched 61 minutes ago" do
          stub_connection_with DESCRIBE_INSTANCES_SINGLE_RESULT_RUNNING_XML
          instance = Awsymandias::EC2::Instance.find("i-some-instance")
          instance.attributes['launch_time'] = 61.minutes.ago.to_s
          expected_cost = instance.instance_type.price_per_hour * 2
          instance.running_cost.should == expected_cost          
        end
        
        it "should be three increments if the instance was launched 150 minutes ago" do
          stub_connection_with DESCRIBE_INSTANCES_SINGLE_RESULT_RUNNING_XML
          instance = Awsymandias::EC2::Instance.find("i-some-instance")
          instance.attributes['launch_time'] = 150.minutes.ago.to_s
          expected_cost = instance.instance_type.price_per_hour * 3
          instance.running_cost.should == expected_cost          
        end
      end
      
      describe "port_open?" do
        it "should return true if telnet does not raise" do
          stub_connection_with DESCRIBE_INSTANCES_SINGLE_RESULT_RUNNING_XML
          instance = Awsymandias::EC2::Instance.find("i-some-instance")
          Net::Telnet.should_receive(:new).with("Host" => "ec2-174-129-118-52.compute-1.amazonaws.com",
                                                "Port" => 100).and_return(true)
          instance.port_open?(100).should be_true
        end
        
        it "should return false if telnet does raise" do
          stub_connection_with DESCRIBE_INSTANCES_SINGLE_RESULT_RUNNING_XML
          instance = Awsymandias::EC2::Instance.find("i-some-instance")
          Net::Telnet.should_receive(:new).with("Host" => "ec2-174-129-118-52.compute-1.amazonaws.com",
                                                "Port" => 100).and_raise(Timeout::Error)
          instance.port_open?(100).should be_false
        end
      end
    end

    describe ApplicationStack = Awsymandias::EC2::ApplicationStack do
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
        Awsymandias::SimpleDB.stub!(:connection).and_return @simpledb
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
            s.role "db1",  :instance_type => Awsymandias::EC2::InstanceTypes::C1_XLARGE
            s.role "app1", :instance_type => Awsymandias::EC2::InstanceTypes::M1_LARGE
          end
  
          Instance.should_receive(:launch).with({ :instance_type => Awsymandias::EC2::InstanceTypes::C1_XLARGE }).and_return(mock("instance1", :instance_id => "a"))
          Instance.should_receive(:launch).with({ :instance_type => Awsymandias::EC2::InstanceTypes::M1_LARGE }).and_return(mock("instance2", :instance_id => "b"))
  
          s.launch
        end
  
        it "should set the getter for the particular instance to the return value of launching the instance" do      
          s = ApplicationStack.new("test") do |s| 
            s.role "db1",  :instance_type => Awsymandias::EC2::InstanceTypes::C1_XLARGE
            s.role "app1", :instance_type => Awsymandias::EC2::InstanceTypes::M1_LARGE
          end
    
          instances = [ stub_instance, stub_instance ]
    
          Instance.stub!(:launch).with({ :instance_type => Awsymandias::EC2::InstanceTypes::C1_XLARGE }).and_return instances.first
          Instance.stub!(:launch).with({ :instance_type => Awsymandias::EC2::InstanceTypes::M1_LARGE }).and_return instances.last
    
          s.db1.should be_nil
          s.app1.should be_nil
          
          s.launch
    
          s.db1.should == instances.first
          s.app1.should == instances.last
        end
  
        it "should store details about the newly launched instances" do
          Awsymandias::EC2::Instance.stub!(:launch).and_return stub_instance(:instance_id => "abc123")
          Awsymandias::EC2::ApplicationStack.new("test") do |s| 
            s.role "db1", :instance_type => Awsymandias::EC2::InstanceTypes::C1_XLARGE
          end.launch
    
          simpledb.get_attributes(ApplicationStack::DEFAULT_SDB_DOMAIN, "test").should == { "db1" => "abc123" }
        end
      end

      describe "launched?" do    
        it "should be false initially" do
          s = ApplicationStack.new("test") {|s| s.role "db1", :instance_type => Awsymandias::EC2::InstanceTypes::M1_LARGE}
          s.should_not be_launched
        end
  
        it "should be true if launched and instances are non-empty" do
          s = ApplicationStack.new("test") { |s| s.role "db1" }
          Awsymandias::EC2::Instance.stub!(:launch).and_return stub_instance
          s.launch
          s.should be_launched
        end
  
        it "should attempt to determine whether or not it's been previously launched" do
          Awsymandias::SimpleDB.put ApplicationStack::DEFAULT_SDB_DOMAIN, "test", "db1" => ["instance_id"]
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
            s.role "db1", :instance_type => Awsymandias::EC2::InstanceTypes::C1_XLARGE
            s.role "app1", :instance_type => Awsymandias::EC2::InstanceTypes::M1_LARGE
          end
    
          Instance.stub!(:launch).
            with({ :instance_type => Awsymandias::EC2::InstanceTypes::C1_XLARGE }).
            and_return stub_instance(:instance_state => { :name => "pending" })
      
          Instance.stub!(:launch).
            with({ :instance_type => Awsymandias::EC2::InstanceTypes::M1_LARGE }).
            and_return stub_instance(:instance_state => { :name => "running" })
      
          s.launch
          s.should_not be_running
        end
  
        it "should be true if launched and all instances are running" do
          s = ApplicationStack.new("test") do |s| 
            s.role "db1", :instance_type => Awsymandias::EC2::InstanceTypes::C1_XLARGE
            s.role "app1", :instance_type => Awsymandias::EC2::InstanceTypes::M1_LARGE
          end
    
          Instance.stub!(:launch).
            with({ :instance_type => Awsymandias::EC2::InstanceTypes::C1_XLARGE }).
            and_return stub_instance(:instance_state => { :name => "running" })
      
          Instance.stub!(:launch).
            with({ :instance_type => Awsymandias::EC2::InstanceTypes::M1_LARGE }).
            and_return stub_instance(:instance_state => { :name => "running" })
      
          s.launch
          s.should be_running
        end
      end
      
      describe "port_open?" do
        it "should return true if there is one instance with the port open" do
          s = ApplicationStack.new("test") do |s| 
            s.role "app1", :instance_type => Awsymandias::EC2::InstanceTypes::C1_XLARGE
          end
  
          instance = stub_instance
          instance.should_receive(:port_open?).with(100).and_return(true)
          Instance.stub!(:launch).and_return(instance)
        
          s.launch
          s.port_open?(100).should be_true
        end
      
        it "should return false if there is one instance with the port closed" do
          s = ApplicationStack.new("test") do |s| 
            s.role "app1", :instance_type => Awsymandias::EC2::InstanceTypes::C1_XLARGE
          end
  
          instance = stub_instance
          instance.should_receive(:port_open?).with(100).and_return(false)
          Instance.stub!(:launch).and_return(instance)
        
          s.launch
          s.port_open?(100).should be_false
        end
        
        it "should return true if there are multiple instances all with the port open" do
          s = ApplicationStack.new("test") do |s| 
            s.role "app1", :instance_type => Awsymandias::EC2::InstanceTypes::C1_XLARGE
            s.role "app2", :instance_type => Awsymandias::EC2::InstanceTypes::C1_XLARGE
          end
  
          instance1, instance2 = [stub_instance, stub_instance]
          instance1.should_receive(:port_open?).with(100).and_return(true)
          instance2.should_receive(:port_open?).with(100).and_return(true)
          Instance.stub!(:launch).and_return(instance1, instance2)
        
          s.launch
          s.port_open?(100).should be_true
        end

        it "should return false if there are multiple instances with at least one port closed" do
          s = ApplicationStack.new("test") do |s| 
            s.role "app1", :instance_type => Awsymandias::EC2::InstanceTypes::C1_XLARGE
            s.role "app2", :instance_type => Awsymandias::EC2::InstanceTypes::C1_XLARGE
          end
  
          instance1, instance2 = [stub_instance, stub_instance]
          instance1.should_receive(:port_open?).with(100).and_return(true)
          instance2.should_receive(:port_open?).with(100).and_return(false)
          Instance.stub!(:launch).and_return(instance1, instance2)
        
          s.launch
          s.port_open?(100).should be_false
        end

      end

      describe "terminate!" do
        it "should not do anything if not running" do
          s = ApplicationStack.new("test") { |s| s.role "db1" }
          Awsymandias::EC2.should_receive(:connection).never
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
          Awsymandias::SimpleDB.put ApplicationStack::DEFAULT_SDB_DOMAIN, "test", "db1" => ["instance_id"]
          s = ApplicationStack.new("test") { |s| s.role "db1" }
          Instance.stub!(:launch).and_return stub('stub').as_null_object
          s.launch
          s.terminate!
          Awsymandias::SimpleDB.get(ApplicationStack::DEFAULT_SDB_DOMAIN, "test").should be_blank
        end
      end
      
      describe "running_cost" do
        it "should be zero if the stack has not been launched" do
          s = ApplicationStack.new("test") {|s| s.role "db1", :instance_type => Awsymandias::EC2::InstanceTypes::M1_LARGE}
          s.running_cost.should == zero_dollars
        end
        
        it "should be the sum total of the running cost of its constituent instances" do
          stack = ApplicationStack.new "test"
          stack.should_receive(:retrieve_role_to_instance_id_mapping).and_return({
            :db  => mock(:instance, :running_cost => Money.new(10)),
            :app => mock(:instance, :running_cost => Money.new(20))
          })
          
          stack.running_cost.should == Money.new(30)
        end
      end
    end
  end
end
