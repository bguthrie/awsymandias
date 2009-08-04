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

    describe 'build_stack' do
      it "should create an application stack object" do
        stackdef = StackDefinition.new('test')
        stackdef.build_stack.name.should == 'test'
      end
      
      it "should populate the unlaunched_instances" do
        stackdef = StackDefinition.new('test')
        stackdef.instance :a, :availability_zone => 'foo'
        stackdef.build_stack.unlaunched_instances[:a].should == { :availability_zone => 'foo' }
      end
      
      it "should populate the volumes" do
        stackdef = StackDefinition.new('test')
        stackdef.volume :a, :unix_device => 'foo'
        stackdef.build_stack.volumes[:a].should == { :unix_device => 'foo' }
      end
      
      it "should populate the roles" do
        stackdef = StackDefinition.new('test')
        stackdef.role :app, :a
        stackdef.build_stack.roles[:app].should == [:a]
      end
    end

 
    describe 'instance' do
      it "should save the instance definition" do
        stackdef = StackDefinition.new 'test'
        stackdef.instance :a, :availability_zone => 'foo', :image_id => 'bar'
        stackdef.defined_instances[:a].should == { :availability_zone => 'foo', :image_id => 'bar' }
      end
      
      it "should allow specifying a single role without mucking up the instance" do
        stackdef = StackDefinition.new 'test'
        stackdef.instance :a, :role => :app
        stackdef.defined_roles[:app].should == [:a]
      end
      
      it "should allow specifying multiple roles without mucking up the instance" do
        stackdef = StackDefinition.new 'test'
        stackdef.instance :a, :roles => [:app, :web, :db]
        stackdef.defined_instances[:a].should == {}
        stackdef.defined_roles.should == { :app => [:a], :web => [:a], :db => [:a]}
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

      it "should allow specifying a single role without mucking up the instance" do
        stackdef = StackDefinition.new 'test'
        stackdef.instances :a, :b, :c, :role => :app
        stackdef.defined_instances.should == { :a => {}, :b => {}, :c => {} }
        stackdef.defined_roles.should == { :app => [:a, :b, :c] }
      end
      
      it "should allow specifying multiple roles without mucking up the instance" do
        stackdef = StackDefinition.new 'test'
        stackdef.instances :a, :b, :c, :roles => [:app, :web, :db]
        stackdef.defined_instances.should == { :a => {}, :b => {}, :c => {} }
        stackdef.defined_roles.should == { :app => [:a, :b, :c], :web => [:a, :b, :c], :db => [:a, :b, :c]}
      end
    end
    
    describe 'role' do
      it "should allow specifying a role to instance mapping" do
        stackdef = StackDefinition.new 'test'
        stackdef.role :app, :a, :b, :c
        stackdef.defined_roles[:app].should == [:a, :b, :c]  
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