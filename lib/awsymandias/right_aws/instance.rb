# An instance represents an AWS instance as derived from a call to EC2's describe-instances methods.
# It wraps the simple hash structures returned by the EC2 gem with a domain model.
# It inherits from ARes::B in order to provide simple XML <-> domain model mapping.
module Awsymandias
  class Instance < ActiveResource::Base
    include Awsymandias::Support::Hash
    extend  Awsymandias::Support::Hash # reformat_incoming_param_data
    
    self.site = "mu"
  
    def id;          instance_id;      end
    def instance_id; aws_instance_id;  end
    def public_dns;  dns_name;         end
    def private_dns; private_dns_name; end

    def attached_volumes
      Awsymandias::RightAws.connection.describe_volumes.select { |volume| volume.aws_instance_id == instance_id }
    end

    def attach_volume(volume_id, unix_device)
      volume_info = Awsymandias::RightAws.connection.describe_volumes(volume_id).first
      if volume_info.aws_status != "available"
        if volume_info.aws_instance_id == instance_id
          Awsymandias.verbose_output "\tVolume #{volume_info} is already attached to #{instance_id}."
          return
        else 
          raise "Volume #{volume_id} is already attached to #{volume_info.aws_instance_id}.  Can't attach to #{instance_id}."
        end
      end

      Awsymandias.verbose_output "\tTrying to attach volume #{volume_id} to #{instance_id} at #{unix_device}"
      volume = Awsymandias::RightAws.connection.attach_volume volume_id, instance_id, unix_device

      Awsymandias.wait_for "volume #{volume.aws_id} to attach to instance #{instance_id} on device #{unix_device}", 3 do
        Awsymandias::RightAws.connection.describe_volumes(volume.aws_id).first.aws_attachment_status == 'attached'
      end
    end

    def detach_volume(volume_id, unix_device)
      Awsymandias::RightAws.connection.detach_volume volume_id, instance_id, unix_device
      Awsymandias.wait_for "volume #{volume_id} to detach..", 3 do
        Awsymandias::RightAws.connection.describe_volumes(volume_id).first.aws_status == 'available'
      end
    end
    
    def key_name
      @attributes['key_name'] || nil
    end

    def pending?
      aws_state == "pending"
    end
  
    def running?
      aws_state == "running"
    end
    
    def port_open?(port)
      Net::Telnet.new("Host" => public_dns, "Port" => port, "Timeout" => 5) 
      true
    rescue Timeout::Error, Errno::ECONNREFUSED
      false
    end
    
    def snapshot_attached?(snapshot_id)
      Awsymandias::RightAws.connection.describe_volumes.each do |volume|
        return true if volume.snapshot_id == snapshot_id && volume.aws_instance_id == instance_id
      end
      false
    end

    def terminated?
      aws_state == "terminated"
    end
  
    def terminate!
      Awsymandias::RightAws.connection.terminate_instances self.instance_id
      reload
    end
  
    def volume_attached_to_unix_device(unix_device)
      attached_volumes.select { |vol| vol.aws_device == unix_device }.first
    end

    def reload
      load( RightAws.connection.describe_instances(self.aws_instance_id).first )
    end
    
    def to_params
      {
        :aws_image_id => self.aws_image_id,
        :ssh_key_name => self.ssh_key_name,
        :aws_instance_type => self.aws_instance_type,
        :aws_availability_zone => self.aws_availability_zone
      }
    end
    
    def aws_instance_type
      Awsymandias::EC2.instance_types[@attributes['aws_instance_type']]
    end
    
    def aws_launch_time
      Time.parse(@attributes['aws_launch_time'])
    end
    
    def uptime
      return 0.seconds if (pending? || terminated?)
      Time.now - self.aws_launch_time
    end
    
    def running_cost
      return Money.new(0) if pending?
      aws_instance_type.price_per_hour * (uptime / 1.hour).ceil 
    end
      
    class << self
      def find(*args)
        opts = args.extract_options!
        ids = args.first == :all ? opts[:instance_ids] : [args.first].flatten
        
        found = RightAws.connection.describe_instances(ids).map do |instance_attributes| 
          instantiate_record instance_attributes
        end
        
        raise ActiveResource::ResourceNotFound.new("Couldn't find instance #{ids.first}.") if (ids.size == 1 && found.size == 0)
        (found.size == 1 && args.first != :all) ? found.first : found
      end
        
      def launch(opts={})
        opts.assert_valid_keys! :image_id, :key_name, :instance_type, :availability_zone, :user_data
        opts[:instance_type] = opts[:instance_type].name if opts[:instance_type].is_a?(Awsymandias::EC2::InstanceType)
      
        response = Awsymandias::RightAws.connection.run_instances *run_instance_opts_to_args(opts)
        find(response.first.aws_instance_id)
      end
      
      private
      
      def run_instance_opts_to_args(opts)
        [
         opts[:image_id], 
         opts[:min_count] || 1, 
         opts[:max_count] || 1, 
         opts[:group_ids] || 'default',
         opts[:key_name],
         
         opts[:user_data],  
         opts[:addressing_type], 
         opts[:instance_type],
         opts[:kernel_id], 
         opts[:ramdisk_id], 
         opts[:availability_zone], 
         opts[:block_device_mappings]
        ]
      end
    end
  end
end
