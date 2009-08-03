module Awsymandias
  module EC2
    class ApplicationStack
      attr_reader :name, :roles, :sdb_domain, :unlaunched_instances, :instances, :volumes

      DEFAULT_SDB_DOMAIN = "application-stack"

      class << self
        def find(name)
          returning(new(name)) do |stack|
            stack.send(:reload_from_metadata!)
            return nil unless stack.launched?
          end
        end

        def launch(name, opts={})
          returning(new(name, opts)) do |stack|
            stack.launch
          end
        end
      end

      def initialize(name, opts={})
        opts.assert_valid_keys :roles, :sdb_domain, :volumes

        @name       = name
        @sdb_domain = opts[:sdb_domain] || DEFAULT_SDB_DOMAIN
        @instances  = {}
        @unlaunched_instances = {}
        @roles = []
        @volumes    = {}
        opts[:volumes].each { |name, opts| volume(name, opts) } if opts[:volumes]

        if opts[:roles]
          opts[:roles].each_pair { |role_name, params| role(role_name, params) }
        end
        yield self if block_given?
      end

      def instances
        !@instances.empty? ? @instances.values : {}
      end

      def role(*names)
        opts = names.extract_options!
        num_instances = opts.delete(:num_instances) || 1
        names.each do |name|
          establish_role(name)
          num_instances.times do |iterator|
            instance_name = "#{name}_#{iterator.to_i + 1}"
            @unlaunched_instances[instance_name] = opts
            define_methods_for_instance(instance_name)
          end
        end
      end
        
      def volume(name, opts = {})
        opts.assert_valid_keys :volume_id, :instance, :unix_device, :snapshot_id, :role, :all_instances
        @volumes[name] = opts
      end

      def establish_role(role_name)
        if !self.metaclass.respond_to?(role_name)
          self.metaclass.send(:define_method, "#{role_name}") {  @instances.values.select { |inst| inst.name =~ /^#{role_name}_/ } }
        end
        @roles << role_name
        @roles.uniq!
      end
    
      def define_methods_for_instance(instance_name)
        establish_role( Awsymandias::Instance.instance_name_to_role(instance_name) ) 
        if !self.metaclass.respond_to?(instance_name)
          self.metaclass.send(:define_method, instance_name) { @instances[instance_name] }
        end
      end

      def launch
        store_app_stack_metadata!
        @unlaunched_instances.each_pair do |instance_name, params|
          @instances[instance_name] = Awsymandias::Instance.launch(params)
          @instances[instance_name].name = instance_name
          @unlaunched_instances.delete instance_name
        end
        attach_volumes
        store_app_stack_metadata!
        self
      end
      
      def attach_volumes
        @volumes.each do |volume, options|
          if options[:instance]
            attach_volume_to_instance options
          elsif options[:role]
            create_and_attach_volumes_to_instances send(options[:role]), options
          elsif options[:all_instances]
            create_and_attach_volumes_to_instances instances, options
          else
            raise "Neither role, instance, or all_instances was specified for #{volume} volume"
          end
        end
      end
      
      def attach_volume_to_instance(options)
        @instances[options[:instance]].attach_once_running options[:volume_id], options[:unix_device]
      end
      
      def create_and_attach_volumes_to_instances(instances, options)                  
        volume_ids = instances.map do |i|
          if already_attached_volume = i.volume_attached_to_unix_device(options[:unix_device])
            raise "Another volume (#{already_attached_volume.aws_id}) is already attached to " + 
                  "instance #{i.instance_id} at #{options[:unix_device]}."
          end
          
          Awsymandias::RightAws.wait_for_create_volume(options[:snapshot_id], i.aws_availability_zone).aws_id
        end
        
        sleep 5 # There seems to be a race condition between when the volume says it is available and actually being able to attach it
                
        instances.zip(volume_ids).each do |i, volume_id|
          i.attach_once_running volume_id, options[:unix_device]
        end
      end
      
      def reload
        raise "Can't reload unless launched" unless launched?
        @instances.values.each(&:reload)
        self
      end

      def terminate!
        store_app_stack_metadata!
        instances.each do |instance|
          instance.terminate! if instance.running?
        end
        remove_app_stack_metadata!
        self
      end

      def launched?
        instances.any?
      end

      def running?
        launched? && @instances.values.all?(&:running?)
      end

      def terminated?
        launched? && @instances.values.all?(&:terminated?)
      end

      def port_open?(port)
        instances.all? { |instance| instance.port_open?(port) }
      end

      def running_cost
        return Money.new(0) unless launched?
        @instances.values.sum { |instance| instance.running_cost }
      end

      def to_s
        inspect
      end
    
      def inspect
        output = []
        output << "   #{name}"
        @instances.each_pair do |instance_name, instance|
          output << "     #{instance_name}\t#{instance.instance_id}\t#{instance.aws_state}\t#{instance.aws_availability_zone}\t#{instance.aws_instance_type.name}\t#{instance.aws_image_id}\t#{instance.public_dns}\tLaunched #{instance.aws_launch_time}"
          instance.attached_volumes.each do |volume|
            output << "         #{volume.aws_id} -> #{volume.aws_device}"
          end
        end
        output
      end

      private

      def store_app_stack_metadata!
        metadata = {}
        metadata[:unlaunched_instances] = @unlaunched_instances
  
        metadata[:instances] = {}
        @instances.each_pair do |instance_name, instance| 
          metadata[:instances][instance_name] = { :aws_instance_id => instance.aws_instance_id, 
                                                  :name => instance.name,
                                                  :attached_volumes => instance.attached_volumes.map { |vol| vol.aws_id }
                                                }
        end          
  
        Awsymandias::SimpleDB.put @sdb_domain, @name, metadata
      end

      def remove_app_stack_metadata!
        Awsymandias::SimpleDB.delete @sdb_domain, @name
      end

      def reload_from_metadata!
        metadata = Awsymandias::SimpleDB.get @sdb_domain, @name 
      
        unless metadata.empty?
          @unlaunched_instances = metadata[:unlaunched_instances]
        
          if !metadata[:instances].empty?
            live_instances = Awsymandias::Instance.find(:all, :instance_ids =>                                   
                                                        metadata[:instances].values.map { |inst| inst[:aws_instance_id] }
                                                       ).index_by(&:instance_id)
            metadata[:instances] = metadata[:instances]
            metadata[:instances].each_pair do |instance_name, instance_metadata|
              @instances[instance_name] = live_instances[instance_metadata[:aws_instance_id]]
              @instances[instance_name].name = instance_name
              define_methods_for_instance(instance_name)
            end
          end
        
          @foo = metadata[:foo]
        end
      end
    end
  end
end
