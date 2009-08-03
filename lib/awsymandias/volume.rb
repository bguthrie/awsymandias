module Awsymandias
  class Volume < ActiveResource::Base
    hash_initializer :aws_size, :aws_device, :aws_attachment_status, :zone, :snapshot_id, :aws_attached_at, :aws_status, :aws_id, :aws_created_at, :aws_instance_id, :stack
    attr_reader :aws_size, :aws_device, :aws_attachment_status, :zone, :snapshot_id, :aws_attached_at, :aws_status, :aws_id, :aws_created_at, :aws_instance_id
    
    def id;        aws_id; end
    def volume_id; aws_id; end

    def attach_to(instance_id, unix_device)
      if attached_to?(instance_id)
        Awsymandias.verbose_output "\tVolume #{volume_id} is already attached to #{instance_id}."
        return
      end
      raise "Volume #{volume_id} is already attached to #{aws_instance_id}.  Can't attach to #{instance_id}." if attached_to_an_instance_other_than?(instance_id)
      
      Awsymandias.verbose_output "\tTrying to attach volume #{volume_id} to #{instance_id} at #{unix_device}"
      connection.attach_volume(volume_id, instance_id, unix_device)
      
      Awsymandias.wait_for "volume #{volume_id} to attach to instance #{instance_id} on device #{unix_device}", 3 do
        reload.attached?
      end
    end

    def detach
      connection.detach_volume volume_id, aws_instance_id, aws_device
      Awsymandias.wait_for "volume #{volume_id} to detach..", 3 do
        reload.available?
      end
    end
    
    def attached?
      aws_attachment_status == 'attached'
    end

    def attached_to?(instance_id)
      attached? && aws_instance_id == instance_id
    end
    
    def attached_to_an_instance_other_than?(instance_id)
      attached? && aws_instance_id != instance_id
    end
    
    def available?
      aws_status == 'available'
    end
    
    def reload
      data = connection.describe_volumes(self.aws_id).first
      data.symbolize_keys!
      data.keys.each do |attribute_name|
        instance_variable_set "@#{attribute_name}", data[attribute_name]
      end
      self
    end
    
    
    
  end
end