module Awsymandias
  class Snapshot < ActiveResource::Base
    hash_initializer :aws_progress, :aws_status, :aws_id, :aws_volume_id, :aws_started_at, :stack
    attr_reader      :aws_progress, :aws_status, :aws_id, :aws_volume_id, :aws_started_at
    
    def self.find(*ids)
      connection.describe_snapshots(ids).map { |s| Awsymandias::Snapshot.new s }
    end
    
    def self.find_by_tag(name)
      tagged_snapshot = SimpleDB.get('snapshots', name)
      find(tagged_snapshot[:snapshot_id]) if tagged_snapshot
    end
    
    def id;          @aws_id; end
    def snapshot_id; @aws_id; end
    
    def size
      connection.describe_volumes([connection.describe_snapshots([snapshot_id]).first[:aws_volume_id]]).first[:aws_size]
    end
    
    def tag(name)
      SimpleDB.put('snapshots', name, :snapshot_id => id)
    end
    
  end
end