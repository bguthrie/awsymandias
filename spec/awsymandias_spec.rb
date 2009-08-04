require 'rubygems'
require 'spec'
require File.expand_path(File.dirname(__FILE__) + "/../lib/awsymandias")

describe Awsymandias do
  describe "stack names" do
    it "returns an array of stack names fetched from SimpleDB" do
      Awsymandias.access_key_id = "configured key"
      Awsymandias.secret_access_key = "configured secret"

      Awsymandias::SimpleDB.should_receive(:connection).and_return(connection = mock("connection"))
      connection.should_receive(:query).with('application-stack','', nil, nil).and_return( { :items => ['x','y','z'] } )
      Awsymandias.stack_names.should == ['x','y','z']
    end
    
    it "remove blank stack names from the returned array" do
      Awsymandias.access_key_id = "configured key"
      Awsymandias.secret_access_key = "configured secret"

      Awsymandias::SimpleDB.should_receive(:connection).and_return(connection = mock("connection"))
        connection.should_receive(:query).with('application-stack','', nil, nil).and_return( { :items => ['x','','y','z' ] } )
      Awsymandias.stack_names.should == ['x','y','z']
    end
  end
  
  describe Awsymandias::SimpleDB do
    describe "connection" do
      it "configure an instance of RightAws::SdbInterface" do
        Awsymandias.access_key_id = "configured key"
        Awsymandias.secret_access_key = "configured secret"
      
        ::RightAws::SdbInterface.should_receive(:new).
          with("configured key", "configured secret", anything).
          and_return(:a_connection)
      
        Awsymandias::SimpleDB.connection.should == :a_connection
      end
    end
    
  end
  
  describe Awsymandias::RightAws do    
    def zero_dollars
      Money.new(0)
    end
    
    describe "connection" do
      it "should configure an instance of RightAws::Ec2" do
        Awsymandias.access_key_id = "configured key"
        Awsymandias.secret_access_key = "configured secret"

        ::RightAws::Ec2.should_receive(:new).
          with("configured key", "configured secret", anything).
          and_return(:a_connection)

        Awsymandias::RightAws.connection.should == :a_connection
      end    
    end
    
  end
end
