require 'rubygems'
require 'spec'
require File.expand_path(File.dirname(__FILE__) + "/../../lib/awsymandias")

describe 'when creating an instance' do
  
  before :all do
    Awsymandias.access_key_id = ENV['AMAZON_ACCESS_KEY_ID'] 
    Awsymandias.secret_access_key = ENV['AMAZON_SECRET_ACCESS_KEY']

    @stack = Awsymandias::EC2::ApplicationStack.define('instances') do |s|
      s.instance :box, :image_id => 'ami-20b65349'
    end
    
    @stack.launch
    Awsymandias.wait_for('stack to start', 5) { @stack.reload.running? }
  end
  
  after :all do
    @stack.terminate!
  end
  
  describe "the box instance" do
    it "should be available through a method on stack" do
      @stack.box.should_not be_nil
    end

    it "should be running" do
      @stack.box.running?.should be_true
    end
  end


  describe "finding the stack in simple db" do
    
    it "should remember the box instance" do
      found_stack = Awsymandias::EC2::ApplicationStack.find('instances')
      found_stack.box.should_not be_nil
      found_stack.box.running?.should be_true
    end
    
  end
  
end