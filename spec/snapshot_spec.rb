require 'rubygems'
require 'spec'
require File.expand_path(File.dirname(__FILE__) + "/../lib/awsymandias")

module Awsymandias
  describe Snapshot do
    
    describe 'tag' do
      it "should save to simpledb the snapshot id" do
        SimpleDB.should_receive(:put).with('snapshots', 'last_good_one', :snapshot_id => 'snapshot-1234')
        
        snapshot = Snapshot.new(:aws_id => 'snapshot-1234')
        snapshot.tag 'last_good_one'
      end
      
      it "should ask simple db for the tag and populate the snapshot object" do
        SimpleDB.should_receive(:get).with('snapshots', 'last_good_one').and_return(:snapshot_id => 'snapshot-1234')
        Snapshot.should_receive(:find).with('snapshot-1234').and_return(Snapshot.new(:aws_id => 'snapshot-1234'))
        
        Snapshot.find_by_tag('last_good_one').id.should == 'snapshot-1234'
      end
    end

    describe "find" do
      it "should return an array of Awsymandias::Snapshot objects." do
        connection = mock('connection')
        connection.should_receive(:describe_snapshots).and_return(
          [{:aws_id => :some_snapshot_id}, {:aws_id => :another_snapshot_id}]
        )
        Snapshot.should_receive(:connection).and_return(connection)
        
        snapshots = Snapshot.find
        snapshots.map(&:aws_id).should == [:some_snapshot_id, :another_snapshot_id]
        snapshots.map(&:class).uniq.should == [Awsymandias::Snapshot]
      end
    end
      
  end
end