require 'rubygems'
require 'spec'
require File.expand_path(File.dirname(__FILE__) + "/../lib/awsymandias")

module Awsymandias
  describe RightAws do
    before :each do
      RightAws.should_receive(:connection).any_number_of_times.and_return(@connection = mock)
    end
    
    def stub_snapshots(snapshots)      
      @connection.should_receive(:describe_snapshots).and_return(snapshots)
    end

    def stub_volumes(volumes)
      @connection.should_receive(:describe_volumes).and_return(volumes)
    end

    describe "latest_snapshot_based_on" do      
      
      it "returns snapshots based on the given volume id" do
        stub_snapshots [{:aws_id => 'snapshot_1', :aws_volume_id => 'some_volume'}, 
                        {:aws_id => 'snapshot_2', :aws_volume_id => 'another_volume'}]
        RightAws.latest_snapshot_based_on('some_volume').should == 'snapshot_1'
      end

      it "does not return snapshots not based on the given volume id" do
        stub_snapshots [{:aws_id => 'snapshot_1', :aws_volume_id => 'another_volume'}, 
                        {:aws_id => 'snapshot_2', :aws_volume_id => 'another_volume'}]
        RightAws.latest_snapshot_based_on('some_volume',false).should == nil
      end

      it "raises an error when no snapshots are found by default" do
        stub_snapshots [{:aws_id => 'snapshot_1', :aws_volume_id => 'another_volume'}, 
                        {:aws_id => 'snapshot_2', :aws_volume_id => 'another_volume'}]
        lambda { RightAws.latest_snapshot_based_on('some_volume') }.should raise_error(RuntimeError, 
                                                                                       "Can't find snapshot for master volume some_volume.")
      end

      it "should return the latest snapshot when there is more than one" do
        stub_snapshots [{:aws_id => 'snapshot_1', :aws_volume_id => 'some_volume', :aws_started_at => Time.parse("2009-12-12 10:00 AM")}, 
                        {:aws_id => 'snapshot_2', :aws_volume_id => 'some_volume', :aws_started_at => Time.parse("2009-12-12 10:02 AM")},
                        {:aws_id => 'snapshot_3', :aws_volume_id => 'some_volume', :aws_started_at => Time.parse("2009-12-12 10:01 AM")}]
        RightAws.latest_snapshot_based_on('some_volume').should == 'snapshot_2'
      end      
    end
    
    describe "snapshot_size" do
      it "returns the size of the volume that the snapshot was based on" do
        stub_snapshots [{:aws_id => 'snapshot_1', :aws_volume_id => 'some_volume'}]
        stub_volumes [{ :aws_id => 'some_volume', :aws_size => 123 }]
        
        RightAws.snapshot_size('snapshot_1').should == 123
      end
    end
    
    describe "wait_for_create_volume" do
      it "should call create_volume and return the volume when its status is 'completed'" do
        stub_volumes [{ :aws_id => 'a_volume_id', :aws_status => 'available' }]
        
        @connection.should_receive(:create_volume).with('some_snapshot',123,'a_zone').and_return(new_volume = mock)
        new_volume.should_receive(:aws_id).any_number_of_times.and_return('a_volume_id')
        RightAws.should_receive(:snapshot_size).and_return(123)
        RightAws.wait_for_create_volume('some_snapshot','a_zone').should == new_volume
      end
    end
    
    describe "wait_for_create_snapshot" do
      it "should call create_snapshot and return the snapshot when its status is 'completed'" do
        stub_snapshots [{ :aws_id => 'a_snapshot_id', :aws_status => 'completed' }]
        @connection.should_receive(:create_snapshot).with('some_volume').and_return(new_snapshot = mock)
        new_snapshot.should_receive(:aws_id).and_return('a_snapshot_id')
        RightAws.wait_for_create_snapshot('some_volume').should == new_snapshot
      end
    end
  end
end