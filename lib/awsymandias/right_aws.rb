module Awsymandias
  module RightAws
    class << self    
      
      def attach_volume(volume_id, instance_id, unix_device)
        Awsymandias::Volume.new connection.attach_volume(volume_id, instance_id, unix_device)
      end
      
      def connection
        @connection ||= ::RightAws::Ec2.new(Awsymandias.access_key_id,  
                                            Awsymandias.secret_access_key, 
                                            {:logger => Logger.new("/dev/null")})
      end      

      def delete_volume(volume_id)
        connection.delete_volume volume_id
      end

      def detach_volume(volume_id, instance_id, unix_device)
        Awsymandias::Volume.new connection.detach_volume(volume_id, instance_id, unix_device)
      end

      def describe_instances(list = [])
        connection.describe_instances(list).map { |i| Awsymandias::Instance.new i }
      end

      def describe_snapshots(list = [])
        connection.describe_snapshots(list).map { |s| Awsymandias::Snapshot.new s }
      end
    
      def describe_volumes(list = [])
        connection.describe_volumes(list).map { |v| Awsymandias::Volume.new v }
      end
    
      def latest_snapshot_based_on(volume_id, raise_if_no_snapshot = true)
        snapshots_for_volume = connection.describe_snapshots.select { |snapshot| snapshot[:aws_volume_id] == volume_id }
        snapshot =  snapshots_for_volume.empty? ? 
                         nil : 
                         snapshots_for_volume.sort { |a,b| a[:aws_started_at] <=> b[:aws_started_at] }.last
        raise "Can't find snapshot for master volume #{volume_id}." if (!snapshot || snapshot[:aws_id].nil?) && raise_if_no_snapshot
        snapshot ? Awsymandias::Snapshot.new(snapshot) : nil
      end

      def snapshot_size(snapshot_id)
        connection.describe_volumes([connection.describe_snapshots([snapshot_id]).first[:aws_volume_id]]).first[:aws_size]
      end  
    
      def delete_snapshot(snapshot_id)
        connection.delete_snapshot snapshot_id
      end

      def wait_for_create_volume(snapshot_id, availability_zone)
        new_volume = connection.create_volume snapshot_id, snapshot_size(snapshot_id), availability_zone

        Awsymandias.wait_for "new volume #{new_volume[:aws_id]} from snapshot #{snapshot_id} to become available..", 3 do
          connection.describe_volumes(new_volume[:aws_id]).first[:aws_status] == 'available'
        end

        Awsymandias::Volume.new new_volume
      end
    
      def wait_for_create_snapshot(volume_id)
        new_snapshot = connection.create_snapshot volume_id
      
        Awsymandias.wait_for "new snapshot of volume #{volume_id}", 3 do
          connection.describe_snapshots(new_snapshot[:aws_id]).first[:aws_status] == 'completed'
        end
      
        Awsymandias::Snapshot.new new_snapshot
      end
    end
  end
end