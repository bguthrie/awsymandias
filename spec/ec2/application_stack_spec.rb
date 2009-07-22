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
        Awsymandias::EC2::Instance.new({:instance_id => "i-12345a3c"}.merge(stubs))
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

          Awsymandias::EC2::Instance.should_receive(:launch).with({ :instance_type => Awsymandias::EC2::InstanceTypes::C1_XLARGE }).and_return(mock("instance1", :instance_id => "a"))
          Awsymandias::EC2::Instance.should_receive(:launch).with({ :instance_type => Awsymandias::EC2::InstanceTypes::M1_LARGE }).and_return(mock("instance2", :instance_id => "b"))

          s.launch
        end

        it "should set the getter for the particular instance to the return value of launching the instance" do      
          s = ApplicationStack.new("test") do |s| 
            s.role "db1",  :instance_type => Awsymandias::EC2::InstanceTypes::C1_XLARGE
            s.role "app1", :instance_type => Awsymandias::EC2::InstanceTypes::M1_LARGE
          end

          instances = [ stub_instance, stub_instance ]

          Awsymandias::EC2::Instance.stub!(:launch).with({ :instance_type => Awsymandias::EC2::InstanceTypes::C1_XLARGE }).and_return instances.first
          Awsymandias::EC2::Instance.stub!(:launch).with({ :instance_type => Awsymandias::EC2::InstanceTypes::M1_LARGE }).and_return instances.last

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
          Awsymandias::EC2::Instance.should_receive(:find).with(:all, :instance_ids => [ "instance_id" ]).and_return [ an_instance ]
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
          Awsymandias::EC2::Instance.stub!(:launch).and_return stub_instance(:instance_state => { :name => "pending" })
          ApplicationStack.new("test") {|s| s.role "db1"}.launch.should_not be_running
        end

        it "should be false if launched and some instances are pended" do
          s = ApplicationStack.new("test") do |s| 
            s.role "db1", :instance_type => Awsymandias::EC2::InstanceTypes::C1_XLARGE
            s.role "app1", :instance_type => Awsymandias::EC2::InstanceTypes::M1_LARGE
          end

          Awsymandias::EC2::Instance.stub!(:launch).
            with({ :instance_type => Awsymandias::EC2::InstanceTypes::C1_XLARGE }).
            and_return stub_instance(:instance_state => { :name => "pending" })

          Awsymandias::EC2::Instance.stub!(:launch).
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

          Awsymandias::EC2::Instance.stub!(:launch).
            with({ :instance_type => Awsymandias::EC2::InstanceTypes::C1_XLARGE }).
            and_return stub_instance(:instance_state => { :name => "running" })

          Awsymandias::EC2::Instance.stub!(:launch).
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
          Awsymandias::EC2::Instance.stub!(:launch).and_return(instance)

          s.launch
          s.port_open?(100).should be_true
        end

        it "should return false if there is one instance with the port closed" do
          s = ApplicationStack.new("test") do |s| 
            s.role "app1", :instance_type => Awsymandias::EC2::InstanceTypes::C1_XLARGE
          end

          instance = stub_instance
          instance.should_receive(:port_open?).with(100).and_return(false)
          Awsymandias::EC2::Instance.stub!(:launch).and_return(instance)

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
          Awsymandias::EC2::Instance.stub!(:launch).and_return(instance1, instance2)

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
          Awsymandias::EC2::Instance.stub!(:launch).and_return(instance1, instance2)

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
          mock_instance = mock("an_instance", :instance_id => "i-foo", :running? => true)
          mock_instance.should_receive(:terminate!)
          Awsymandias::EC2::Instance.stub!(:launch).and_return(mock_instance)
          s.launch
          s.terminate!      
        end

        it "should remove any stored role name mappings" do
          Awsymandias::SimpleDB.put ApplicationStack::DEFAULT_SDB_DOMAIN, "test", "db1" => ["instance_id"]
          s = ApplicationStack.new("test") { |s| s.role "db1" }
          Awsymandias::EC2::Instance.stub!(:launch).and_return stub('stub').as_null_object
          s.launch
          s.terminate!
          Awsymandias::SimpleDB.get(ApplicationStack::DEFAULT_SDB_DOMAIN, "test").should be_blank
        end
      end

      describe "running_cost" do
        it "should be zero if the stack has not been launched" do
          s = ApplicationStack.new("test") {|s| s.role "db1", :instance_type => Awsymandias::EC2::InstanceTypes::M1_LARGE}
          s.running_cost.should == Money.new(0)
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