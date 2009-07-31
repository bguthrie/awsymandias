require 'rubygems'
require 'spec'
require File.expand_path(File.dirname(__FILE__) + "/../lib/awsymandias")

module Awsymandias
  describe StackDefinition do
    
    describe 'initialize' do
      it "should populate the name" do
        stackdef = StackDefinition.new('test')
        stackdef.name.should == 'test'
      end
    end
 
    describe 'instance' do
      it "should save the instance definition" do
        stackdef = StackDefinition.new 'test'
        stackdef.instance :a, :availability_zone => 'foo', :image_id => 'bar'
        stackdef.defined_instances[:a].should == { :availability_zone => 'foo', :image_id => 'bar' }
      end
    end
    
    describe 'instances' do
      it "should allow defining many instances" do
        stackdef = StackDefinition.new 'test'
        stackdef.instances :a, :b, :c, :availability_zone => 'foo', :image_id => 'bar'
        stackdef.defined_instances[:a].should == { :availability_zone => 'foo', :image_id => 'bar' }
        stackdef.defined_instances[:b].should == { :availability_zone => 'foo', :image_id => 'bar' }
        stackdef.defined_instances[:c].should == { :availability_zone => 'foo', :image_id => 'bar' }          
      end
    end
 
    describe 'volume' do
      it "should allow defining a single volume" do
        stackdef = StackDefinition.new 'test'
        stackdef.volume :a, :size => 40, :snapshot_id => 'foo'
        stackdef.defined_volumes[:a].should == { :size => 40, :snapshot_id => 'foo' }
      end
    end
    
    describe 'volumes' do
      it "should allow defining many volumes" do
        stackdef = StackDefinition.new 'test'
        stackdef.volumes :a, :b, :c, :size => 40, :snapshot_id => 'foo'
        stackdef.defined_volumes[:a].should == { :size => 40, :snapshot_id => 'foo' }
        stackdef.defined_volumes[:b].should == { :size => 40, :snapshot_id => 'foo' }          
        stackdef.defined_volumes[:c].should == { :size => 40, :snapshot_id => 'foo' }          
      end
    end
    
  end
end