require 'rubygems'
require 'spec'
require File.expand_path(File.dirname(__FILE__) + "/../../lib/awsymandias")

module Awsymandias
  module EC2
    describe ApplicationStack do
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
        instance_defaults = {:aws_instance_type=>"m1.large",
                             :ami_launch_index=>"0",
                             :aws_reason=>"",
                             :aws_launch_time=>"2009-07-23T13:57:22.000Z",
                             :aws_owner=>"423319072129",
                             :ssh_key_name=>"gsg-keypair",
                             :aws_reservation_id=>"r-dd6733b4",
                             :aws_kernel_id=>"aki-b51cf9dc",
                             :aws_instance_id=>"i-12345a3c",
                             :aws_availability_zone=>"us-east-1b",
                             :aws_state=>"running",
                             :aws_groups=>["default"],
                             :aws_ramdisk_id=>"ari-b31cf9da",
                             :aws_image_id=>"ami-some-image",
                             :dns_name=>"ec2-174-129-118-52.compute-1.amazonaws.com",
                             :aws_state_code=>"16",
                             :aws_product_codes=>[],
                             :private_dns_name=>"ip-10-244-226-239.ec2.internal"}
        instance = Instance.new(instance_defaults.merge(stubs))
        instance.should_receive(:attached_volumes).any_number_of_times.and_return([])
        instance
      end

      before :each do
        @simpledb = SimpleDBStub.new
        SimpleDB.stub!(:connection).and_return @simpledb
      end

      it "should have a name" do
         ApplicationStack.new("foo").name.should == "foo"
       end
     
      describe "roles" do
        it "should be empty by default" do
           ApplicationStack.new("foo").unlaunched_instances.should be_empty
         end
     
         it "should be settable through the initializer" do
           stack = ApplicationStack.new("foo", :roles => { :app => {:some_key => :some_value} })
           stack.unlaunched_instances["app_1"].should == {:some_key => :some_value}
         end
       end
    
      describe "role" do
        it "should allow the definition of a basic, empty role" do
          stack = ApplicationStack.new("foo") do |s|
            s.role :app
          end
          stack.unlaunched_instances["app_1"].should == {}
        end
      
        it "should use the parameters given to the role definition" do
          stack = ApplicationStack.new("foo") do |s|
            s.role :app, :foo => "bar"
          end
          stack.unlaunched_instances["app_1"].should == { :foo => "bar" }
        end
          

        it "should allow for the creation of multiple roles" do
          stack = ApplicationStack.new("foo") do |s|
            s.role :app, :foo => "bar"
            s.role :db,  :foo => "baz"
          end
          stack.unlaunched_instances["app_1"].should == { :foo => "bar" }
          stack.unlaunched_instances["db_1"].should ==  { :foo => "baz" }
        end
      
        it "should map multiple roles to the same set of parameters" do
          stack = ApplicationStack.new("foo") do |s|
            s.role :app, :db, :foo => "bar"
          end
          stack.unlaunched_instances["app_1"].should == { :foo => "bar" }
          stack.unlaunched_instances["db_1"].should  == { :foo => "bar" }
        end
      
        it "should create an accessor mapped to the new role, nil by default" do
          stack = ApplicationStack.new("foo") do |s|
            s.role :app, :foo => "bar"
          end
          stack.app.should == []
        end
    
        it "should create an accessor mapped to each instance in the new role, nil by default" do
          stack = ApplicationStack.new("foo") do |s|
            s.role :app, :num_instances => 2, :foo => "bar"
          end
          stack.app_1.should be_nil
          stack.app_2.should be_nil
        end
      end

      describe "volumes" do
        it "should be empty by default" do
          ApplicationStack.new("foo").volumes.should be_empty
        end

        it "should be settable through the initializer" do
          stack = ApplicationStack.new("foo", :volumes => { :db => {} })
          stack.volumes[:db].should == {}
        end

        it "should not allow invalid options" do
          lambda do
            stack = ApplicationStack.new("foo", :volumes => { :db => {:some_key => "123"} })
          end.should raise_error
        end
      end

      describe "volume" do
        it "should use the parameters given to the volume definition" do
          stack = ApplicationStack.new("foo") do |s|
            s.volume :some_volume, :volume_id => "vol-123"
          end
          stack.volumes[:some_volume].should == { :volume_id => "vol-123" }
        end

        it "should allow multiple volumes" do
          stack = ApplicationStack.new("foo") do |s|
            s.volume :volume_1, :volume_id => "vol-123"
            s.volume :volume_2, :volume_id => "vol-456"
          end
          stack.volumes[:volume_1].should == { :volume_id => "vol-123" }
          stack.volumes[:volume_2].should == { :volume_id => "vol-456" }
        end

        it "should allow volume_id, role, and unix_device as options" do
          stack = ApplicationStack.new("foo") do |s|
            s.volume :volume_1, :volume_id => "vol-123", :instance => "foo", :unix_device => "/dev/sdj"
          end
          stack.volumes[:volume_1].should == { :volume_id => "vol-123", :instance => "foo", :unix_device => "/dev/sdj" }
        end

        it "should not allow invalid options" do
          lambda do
            stack = ApplicationStack.new("foo") do |s|
              s.volume :volume_1, :something_else => "foo"
            end
          end.should raise_error
        end
      end

     
      describe "simpledb_domain" do
        it "should map to ApplicationStack::DEFAULT_SIMPLEDB_DOMAIN upon creation" do
          ApplicationStack.new("foo").simpledb_domain.should == ApplicationStack::DEFAULT_SIMPLEDB_DOMAIN
        end
    
        it "should be configurable" do
          ApplicationStack.new("foo", :simpledb_domain => "a domain").simpledb_domain.should == "a domain"
        end
      end
    
      describe 'define' do
        it "should store the stack name" do
          ApplicationStack.define('name').name.should == 'name'
        end
        
        it "should allow defining instances with a block" do
          definition = ApplicationStack.define('name') do
            instance :foo, :image_id => 'foo'
          end
          definition.defined_instances[:foo].should == { :image_id => 'foo' }
        end
        
        
      end
    
      describe "launch" do
        it "should launch its roles when launched" do
          s = ApplicationStack.new("test") do |s| 
            s.role "db",  :instance_type => InstanceTypes::C1_XLARGE
            s.role "app", :instance_type => InstanceTypes::M1_LARGE
          end
        
          s.should_receive(:store_app_stack_metadata!).any_number_of_times.and_return(nil)
          inst1 = stub_instance :instance_type => InstanceTypes::C1_XLARGE
        
          Instance.should_receive(:launch).
            with({ :instance_type => InstanceTypes::C1_XLARGE }).
            and_return(inst1)
          
          inst2 = stub_instance :instance_type => InstanceTypes::M1_LARGE
        
          Instance.should_receive(:launch).
            with({ :instance_type => InstanceTypes::M1_LARGE }).
            and_return(inst2)
        
          s.launch
        end
      
        it "should set the getter for the particular instance to the return value of launching the instance" do  
          s = ApplicationStack.new("test") do |s| 
            s.role "db",  :instance_type => InstanceTypes::C1_XLARGE
            s.role "app", :instance_type => InstanceTypes::M1_LARGE
          end
          s.should_receive(:store_app_stack_metadata!).any_number_of_times.and_return(nil)
        
          instance_1 = stub_instance
          instance_2 = stub_instance
        
          Instance.stub!(:launch).
            with({ :instance_type => InstanceTypes::C1_XLARGE }).
            and_return instance_1
          Instance.stub!(:launch).
            with({ :instance_type => InstanceTypes::M1_LARGE }).
            and_return instance_2
        
          s.db_1.should be_nil
          s.app_1.should be_nil
        
          s.launch
        
          s.db_1.should == instance_1
          s.app_1.should == instance_2
        end
      
        it "should remove the instance from unlaunched_instances after it has been launched" do
          s = ApplicationStack.new("test") do |s| 
            s.role "db",  :instance_type => InstanceTypes::C1_XLARGE
          end
          s.should_receive(:store_app_stack_metadata!).any_number_of_times.and_return(nil)
        
          inst = mock("instance1", :aws_instance_id => "a", :attached_volumes => [])
          inst.should_receive(:name=)
          Instance.should_receive(:launch).
            with({ :instance_type => InstanceTypes::C1_XLARGE }).
            and_return(inst)
                  
          s.unlaunched_instances["db_1"].should_not be_nil
          s.launch
          s.unlaunched_instances["db_1"].should be_nil
        end
      
        it "should store details about the newly launched instances" do
          Instance.stub!(:launch).and_return stub_instance(:aws_instance_id => "abc123")
          stack = ApplicationStack.new("test") do |s| 
            s.role "db_1", :instance_type => InstanceTypes::C1_XLARGE
          end
          stack.should_receive(:store_app_stack_metadata!).at_least(:once)
          stack.launch
        end

        it "should attach volumes when launched" do
          s = ApplicationStack.new("test") do |s| 
            s.role "db", :instance_type => InstanceTypes::M1_LARGE
            s.volume "production_data", :volume_id => "vol-123", :instance => "db_1", :unix_device => "/dev/sdj"
          end

          s.should_receive(:store_app_stack_metadata!).any_number_of_times.and_return(nil)
        
          instance = stub_instance

          Instance.should_receive(:launch).and_return(instance)
          instance.should_receive(:reload).and_return(instance)
          instance.should_receive(:running?).and_return(true)
          instance.should_receive(:attach_volume).with("vol-123", "/dev/sdj")

          s.launch
        end

      end
      
      describe "launched?" do    
        it "should be false initially" do
          s = ApplicationStack.new("test") {|s| s.role "db", :instance_type => InstanceTypes::M1_LARGE}
          s.launched?.should be_false
        end
        
        it "should be true if launched and instances are non-empty" do
          s = ApplicationStack.new("test") { |s| s.role "db" }
          s.should_receive(:store_app_stack_metadata!).any_number_of_times.and_return(nil)
          Instance.stub!(:launch).and_return stub_instance
          s.launch
          s.launched?.should be_true
        end
      end
  
      describe "running?" do
        it "should be false initially" do
          ApplicationStack.new("test") {|s| s.role "db_1"}.should_not be_running
        end
  
        it "should be false if launched but all instances are pending" do
          Instance.stub!(:launch).and_return stub_instance(:aws_state => { :name => "pending" })
          s = ApplicationStack.new("test") {|s| s.role "db_1"}
          s.should_receive(:store_app_stack_metadata!).any_number_of_times.and_return(nil)
          s.launch.should_not be_running
        end
  
        it "should be false if launched and some instances are pending" do
          s = ApplicationStack.new("test") do |s| 
            s.role "db_1", :instance_type => InstanceTypes::C1_XLARGE
            s.role "app_1", :instance_type => InstanceTypes::M1_LARGE
          end
          s.should_receive(:store_app_stack_metadata!).any_number_of_times.and_return(nil)
        
          Instance.stub!(:launch).
            with({ :instance_type => InstanceTypes::C1_XLARGE }).
            and_return stub_instance(:aws_state => { :name => "pending" })
        
          Instance.stub!(:launch).
            with({ :instance_type => InstanceTypes::M1_LARGE }).
            and_return stub_instance(:aws_state => { :name => "running" })
        
          s.launch
          s.should_not be_running
        end
  
        it "should be true if launched and all instances are running" do
          s = ApplicationStack.new("test") do |s| 
            s.role "db_1", :instance_type => InstanceTypes::C1_XLARGE
            s.role "app_1", :instance_type => InstanceTypes::M1_LARGE
          end
          s.should_receive(:store_app_stack_metadata!).any_number_of_times.and_return(nil)
        
          Instance.stub!(:launch).
            with({ :instance_type => InstanceTypes::C1_XLARGE }).
            and_return stub_instance(:aws_state => "running")
        
          Instance.stub!(:launch).
            with({ :instance_type => InstanceTypes::M1_LARGE }).
            and_return stub_instance(:aws_state => "running")
        
          s.launch
          s.should be_running
        end
      end
  
      describe "port_open?" do
        it "should return true if there is one instance with the port open" do
          s = ApplicationStack.new("test") do |s| 
            s.role "app", :instance_type => InstanceTypes::C1_XLARGE
          end
          s.should_receive(:store_app_stack_metadata!).any_number_of_times.and_return(nil)
        
          instance = stub_instance
          instance.should_receive(:port_open?).with(100).and_return(true)
          Instance.stub!(:launch).and_return(instance)
        
          s.launch
          s.port_open?(100).should be_true
        end
  
        it "should return false if there is one instance with the port closed" do
          s = ApplicationStack.new("test") do |s| 
            s.role "app", :instance_type => InstanceTypes::C1_XLARGE
          end
          s.should_receive(:store_app_stack_metadata!).any_number_of_times.and_return(nil)
        
          instance = stub_instance
          instance.should_receive(:port_open?).with(100).and_return(false)
          Instance.stub!(:launch).and_return(instance)
        
          s.launch
          s.port_open?(100).should be_false
        end
        
        it "should return true if there are multiple instances all with the port open" do
          s = ApplicationStack.new("test") do |s| 
            s.role "app1", :instance_type => InstanceTypes::C1_XLARGE
            s.role "app2", :instance_type => InstanceTypes::C1_XLARGE
          end
          s.should_receive(:store_app_stack_metadata!).any_number_of_times.and_return(nil)
        
          instance1, instance2 = [stub_instance, stub_instance]
          instance1.should_receive(:port_open?).with(100).and_return(true)
          instance2.should_receive(:port_open?).with(100).and_return(true)
          Instance.stub!(:launch).and_return(instance1, instance2)
        
          s.launch
          s.port_open?(100).should be_true
        end
        
        it "should return false if there are multiple instances with at least one port closed" do
          s = ApplicationStack.new("test") do |s| 
            s.role "app1", :instance_type => InstanceTypes::C1_XLARGE
            s.role "app2", :instance_type => InstanceTypes::C1_XLARGE
          end
          s.should_receive(:store_app_stack_metadata!).any_number_of_times.and_return(nil)
        
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
          s = ApplicationStack.new("test") { |s| s.role "db" }
          s.should_receive(:remove_app_stack_metadata!).once.and_return(nil)
          s.should_receive(:store_app_stack_metadata!).any_number_of_times.and_return(nil)
          RightAws.should_receive(:connection).never
          s.terminate!
        end
  
        it "should terminate all instances if running" do
          s = ApplicationStack.new("test") { |s| s.role "db" }
          s.should_receive(:remove_app_stack_metadata!).once.and_return(nil)
          s.should_receive(:store_app_stack_metadata!).any_number_of_times.and_return(nil)
          mock_instance = mock("an_instance", :aws_instance_id => "i-foo", :running? => true, :attached_volumes => [])
          mock_instance.should_receive(:name=).any_number_of_times
          mock_instance.should_receive(:name).any_number_of_times
          mock_instance.should_receive(:terminate!)
          Instance.stub!(:launch).and_return(mock_instance)
          s.launch
          s.terminate!      
        end
  
        it "should remove any stored role name mappings" do
          s = ApplicationStack.new("test") { |s| s.role "db_1" }
          s.should_receive(:remove_app_stack_metadata!).once.and_return(nil)
          s.should_receive(:store_app_stack_metadata!).any_number_of_times.and_return(nil)
          mock_instance = mock("an_instance", :aws_instance_id => "i-foo", :running? => true, :attached_volumes => [])
          mock_instance.should_receive(:name=).any_number_of_times
          mock_instance.should_receive(:name).any_number_of_times
          mock_instance.should_receive(:terminate!)
          Instance.stub!(:launch).and_return(mock_instance)
          s.launch
          s.terminate!
        end
      end
  
      describe "running_cost" do
        it "should be zero if the stack has not been launched" do
          s = ApplicationStack.new("test") {|s| s.role "db", :instance_type => InstanceTypes::M1_LARGE}
          s.running_cost.should == Money.new(0)
        end
  
        it "should be the sum total of the running cost of its constituent instances" do
          inst1 = Instance.new  :aws_instance_type => 'm1.small', 
                                             :aws_state => 'running', 
                                             :aws_launch_time => 5.minutes.ago.strftime("%Y-%m-%dT%H:%M:00.000EDT")
          inst2 = Instance.new  :aws_instance_type => 'c1.medium', 
                                             :aws_state => 'running', 
                                             :aws_launch_time => 5.minutes.ago.strftime("%Y-%m-%dT%H:%M:00.000EDT")
        
          stack = ApplicationStack.new "test"
          stack.should_receive(:launched?).and_return(true)
          stack.instance_variable_set :"@instances", {'inst1' => inst1, 'inst2' =>  inst2}
        
          stack.running_cost.should == Money.new(30)
        end
      end
    
      describe "find" do
        ##  We *really* need some tests around this
      end
    
      describe "reload_from_metadata!" do
        ##  We *really* need some tests around this
      end
    
      describe "store_app_stack_metadata!" do
        ##  We *really* need some tests around this
      end
    end
  end
end
