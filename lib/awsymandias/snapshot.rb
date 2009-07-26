module Awsymandias
  class Snapshot < ActiveResource::Base
    hash_initializer :aws_progress, :aws_status, :aws_id, :aws_volume_id, :aws_started_at, :stack
    attr_reader      :aws_progress, :aws_status, :aws_id, :aws_volume_id, :aws_started_at
    
    def id;          @aws_id; end
    def snapshot_id; @aws_id; end
    
    def size
      connection.describe_volumes([connection.describe_snapshots([snapshot_id]).first[:aws_volume_id]]).first[:aws_size]
    end    
  end
end