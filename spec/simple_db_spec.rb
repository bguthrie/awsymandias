require 'rubygems'
require 'spec'
require File.expand_path(File.dirname(__FILE__) + "/../lib/awsymandias")

module Awsymandias
  describe SimpleDB do
    
    describe 'put' do
      it "should create a domain if it is missing" do
        stub_connection do |connection|
          connection.should_receive(:list_domains).and_return(:domains => [])
          connection.should_receive(:create_domain).with('missing_domain')
        end
        
        SimpleDB.put('missing_domain', 'key', {})
      end
      
      it "should YAMLize each of the attributes" do
        stub_connection do |connection|
          connection.should_receive(:put_attributes).with('domain', 'key',
            { :foo => 'foo'.to_yaml, :bar => {:baz => 'hmm'}.to_yaml }, true
          )
        end
        
        SimpleDB.put('domain', 'key', {:foo => 'foo', :bar => {:baz => 'hmm'}})
      end
    end
    
    describe 'get' do
      it "should unYAMLize each of the attributes when found" do
        stub_connection do |connection|
          connection.should_receive(:get_attributes).and_return({
            :attributes => { :foo => 'foo'.to_yaml, :bar => {:baz => 'hmm'}.to_yaml }
          })
        end
        
        SimpleDB.get('domain', 'key').should == {:foo => 'foo', :bar => {:baz => 'hmm'}}
      end
      
    end
    

    def stub_connection
      stub = StubSdbConnection.new
      yield stub if block_given?
      SimpleDB.should_receive(:connection).any_number_of_times.and_return(stub)
    end
    
    class StubSdbConnection
      def put_attributes(*args);end
      def get_attributes(domain, name);end
      def delete_attributes(domain, name);end
      def query(*args);end
      def query_with_attributes(*args);end
      def list_domains;
        { :domains => ['domain'] }
      end
      def create_domain(domain);end
    end
    
  end
end