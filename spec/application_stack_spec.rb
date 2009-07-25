require 'rubygems'
require 'spec'
require File.expand_path(File.dirname(__FILE__) + "/../lib/awsymandias")

module Awsymandias
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
      instance = Awsymandias::Instance.new({:aws_instance_id => "i-12345a3c"}.merge(stubs))
      instance.should_receive(:attached_volumes).any_number_of_times.and_return([])
      instance
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
          s.role "db",  :instance_type => Awsymandias::EC2::InstanceTypes::C1_XLARGE
          s.role "app", :instance_type => Awsymandias::EC2::InstanceTypes::M1_LARGE
        end
        
        inst1 = mock("instance1", :aws_instance_id => "a", :attached_volumes => [])
        inst1.should_receive(:name=)
        inst1.should_receive(:name)
        Awsymandias::Instance.should_receive(:launch).
          with({ :instance_type => Awsymandias::EC2::InstanceTypes::C1_XLARGE }).
          and_return(inst1)
          
        inst2 = mock("instance2", :aws_instance_id => "b", :attached_volumes => [])
        inst2.should_receive(:name=)
        inst2.should_receive(:name)
        Awsymandias::Instance.should_receive(:launch).
          with({ :instance_type => Awsymandias::EC2::InstanceTypes::M1_LARGE }).
          and_return(inst2)
        
        s.launch
      end
      
      it "should set the getter for the particular instance to the return value of launching the instance" do  
        s = ApplicationStack.new("test") do |s| 
          s.role "db",  :instance_type => Awsymandias::EC2::InstanceTypes::C1_XLARGE
          s.role "app", :instance_type => Awsymandias::EC2::InstanceTypes::M1_LARGE
        end
        
        instance_1 = stub_instance
        instance_2 = stub_instance
        
        Awsymandias::Instance.stub!(:launch).
          with({ :instance_type => Awsymandias::EC2::InstanceTypes::C1_XLARGE }).
          and_return instance_1
        Awsymandias::Instance.stub!(:launch).
          with({ :instance_type => Awsymandias::EC2::InstanceTypes::M1_LARGE }).
          and_return instance_2
        
        s.db_1.should be_nil
        s.app_1.should be_nil
        
        s.launch
        
        s.db_1.should == instance_1
        s.app_1.should == instance_2
      end
      
      it "should remove the instance from unlaunched_instances after it has been launched" do
        s = ApplicationStack.new("test") do |s| 
          s.role "db",  :instance_type => Awsymandias::EC2::InstanceTypes::C1_XLARGE
        end
        
        inst = mock("instance1", :aws_instance_id => "a", :attached_volumes => [])
        inst.should_receive(:name=)
        inst.should_receive(:name)
        Awsymandias::Instance.should_receive(:launch).
          with({ :instance_type => Awsymandias::EC2::InstanceTypes::C1_XLARGE }).
          and_return(inst)
                  
        s.unlaunched_instances["db_1"].should_not be_nil
        s.launch
        s.unlaunched_instances["db_1"].should be_nil
      end
      
      it "should store details about the newly launched instances" do
        Awsymandias::Instance.stub!(:launch).and_return stub_instance(:aws_instance_id => "abc123")
        stack = Awsymandias::ApplicationStack.new("test") do |s| 
          s.role "db_1", :instance_type => Awsymandias::EC2::InstanceTypes::C1_XLARGE
        end
        stack.should_receive(:store_app_stack_metadata!).at_least(:once)
        stack.launch
      end
    end
      
    describe "launched?" do    
      it "should be false initially" do
        s = ApplicationStack.new("test") {|s| s.role "db", :instance_type => Awsymandias::EC2::InstanceTypes::M1_LARGE}
        s.launched?.should be_false
      end
        
      it "should be true if launched and instances are non-empty" do
        s = ApplicationStack.new("test") { |s| s.role "db" }
        Awsymandias::Instance.stub!(:launch).and_return stub_instance
        s.launch
        s.launched?.should be_true
      end
    end
  
    describe "running?" do
      it "should be false initially" do
        ApplicationStack.new("test") {|s| s.role "db_1"}.should_not be_running
      end
  
      it "should be false if launched but all instances are pending" do
        Awsymandias::Instance.stub!(:launch).and_return stub_instance(:aws_state => { :name => "pending" })
        ApplicationStack.new("test") {|s| s.role "db_1"}.launch.should_not be_running
      end
  
      it "should be false if launched and some instances are pending" do
        s = ApplicationStack.new("test") do |s| 
          s.role "db_1", :instance_type => Awsymandias::EC2::InstanceTypes::C1_XLARGE
          s.role "app_1", :instance_type => Awsymandias::EC2::InstanceTypes::M1_LARGE
        end
        
        Awsymandias::Instance.stub!(:launch).
          with({ :instance_type => Awsymandias::EC2::InstanceTypes::C1_XLARGE }).
          and_return stub_instance(:aws_state => { :name => "pending" })
        
        Awsymandias::Instance.stub!(:launch).
          with({ :instance_type => Awsymandias::EC2::InstanceTypes::M1_LARGE }).
          and_return stub_instance(:aws_state => { :name => "running" })
        
        s.launch
        s.should_not be_running
      end
  
      it "should be true if launched and all instances are running" do
        s = ApplicationStack.new("test") do |s| 
          s.role "db_1", :instance_type => Awsymandias::EC2::InstanceTypes::C1_XLARGE
          s.role "app_1", :instance_type => Awsymandias::EC2::InstanceTypes::M1_LARGE
        end
        
        Awsymandias::Instance.stub!(:launch).
          with({ :instance_type => Awsymandias::EC2::InstanceTypes::C1_XLARGE }).
          and_return stub_instance(:aws_state => "running")
        
        Awsymandias::Instance.stub!(:launch).
          with({ :instance_type => Awsymandias::EC2::InstanceTypes::M1_LARGE }).
          and_return stub_instance(:aws_state => "running")
        
        s.launch
        s.should be_running
      end
    end
  
    describe "port_open?" do
      it "should return true if there is one instance with the port open" do
        s = ApplicationStack.new("test") do |s| 
          s.role "app", :instance_type => Awsymandias::EC2::InstanceTypes::C1_XLARGE
        end
        
        instance = stub_instance
        instance.should_receive(:port_open?).with(100).and_return(true)
        Awsymandias::Instance.stub!(:launch).and_return(instance)
        
        s.launch
        s.port_open?(100).should be_true
      end
  
      it "should return false if there is one instance with the port closed" do
        s = ApplicationStack.new("test") do |s| 
          s.role "app", :instance_type => Awsymandias::EC2::InstanceTypes::C1_XLARGE
        end
        
        instance = stub_instance
        instance.should_receive(:port_open?).with(100).and_return(false)
        Awsymandias::Instance.stub!(:launch).and_return(instance)
        
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
        Awsymandias::Instance.stub!(:launch).and_return(instance1, instance2)
        
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
        Awsymandias::Instance.stub!(:launch).and_return(instance1, instance2)
        
        s.launch
        s.port_open?(100).should be_false
      end
  
    end
  
    describe "terminate!" do
      it "should not do anything if not running" do
        s = ApplicationStack.new("test") { |s| s.role "db" }
        Awsymandias::RightAws.should_receive(:connection).never
        s.terminate!
      end
  
      it "should terminate all instances if running" do
        s = ApplicationStack.new("test") { |s| s.role "db" }
        mock_instance = mock("an_instance", :aws_instance_id => "i-foo", :running? => true, :attached_volumes => [])
        mock_instance.should_receive(:name=).any_number_of_times
        mock_instance.should_receive(:name).any_number_of_times
        mock_instance.should_receive(:terminate!)
        Awsymandias::Instance.stub!(:launch).and_return(mock_instance)
        s.launch
        s.terminate!      
      end
  
      it "should remove any stored role name mappings" do
        Awsymandias::SimpleDB.put ApplicationStack::DEFAULT_SDB_DOMAIN, "test", "db_1" => ["instance_id"]
        s = ApplicationStack.new("test") { |s| s.role "db_1" }
        mock_instance = mock("an_instance", :aws_instance_id => "i-foo", :running? => true, :attached_volumes => [])
        mock_instance.should_receive(:name=).any_number_of_times
        mock_instance.should_receive(:name).any_number_of_times
        mock_instance.should_receive(:terminate!)
        Awsymandias::Instance.stub!(:launch).and_return(mock_instance)
        s.launch
        s.terminate!
        Awsymandias::SimpleDB.get(ApplicationStack::DEFAULT_SDB_DOMAIN, "test").should be_blank
      end
    end
  
    describe "running_cost" do
      it "should be zero if the stack has not been launched" do
        s = ApplicationStack.new("test") {|s| s.role "db", :instance_type => Awsymandias::EC2::InstanceTypes::M1_LARGE}
        s.running_cost.should == Money.new(0)
      end
  
      it "should be the sum total of the running cost of its constituent instances" do
        inst1 = Awsymandias::Instance.new  :aws_instance_type => 'm1.small', 
                                           :aws_state => 'running', 
                                           :aws_launch_time => 5.minutes.ago.strftime("%Y-%m-%dT%H:%M:00.000EDT")
        inst2 = Awsymandias::Instance.new  :aws_instance_type => 'c1.medium', 
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