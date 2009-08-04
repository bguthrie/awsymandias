module Awsymandias
  module EC2
    class ApplicationStack
      attr_reader :name, :simpledb_domain, :unlaunched_instances, :instances, :volumes, :roles

      DEFAULT_SIMPLEDB_DOMAIN = "application-stack"

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
        opts.assert_valid_keys :instances, :simpledb_domain, :volumes, :roles

        @name       = name
        @simpledb_domain = opts[:simpledb_domain] || DEFAULT_SIMPLEDB_DOMAIN
        @instances  = {}
        @unlaunched_instances = {}
        @volumes    = {}
        @roles = {}
        
        if opts[:roles]
          @roles = opts[:roles]
          @roles.keys.each { |role| define_methods_for_role(role) }
        end
        
        if opts[:instances]
          @unlaunched_instances = opts[:instances]
          opts[:instances].each { |name, configuration| define_methods_for_instance(name) }
        end
      
        opts[:volumes].each { |name, opts| volume(name, opts) } if opts[:volumes]
      end
      
      def self.define(name, &block)
        definition = StackDefinition.new(name)
        definition.instance_eval(&block) if block_given?
        definition.build_stack
      end

      def instances
        !@instances.empty? ? @instances.values : {}
      end

      def volume(name, opts = {})
        opts.assert_valid_keys :volume_id, :instance, :unix_device
        @volumes[name] = opts
      end

      def define_methods_for_instance(instance_name)
        if !self.metaclass.respond_to?(instance_name)
          self.metaclass.send(:define_method, instance_name) { @instances[instance_name] }
        end
      end

      def define_methods_for_role(role_name)
        self.metaclass.send(:define_method, role_name) do
          @roles[role_name].map { |instance_name| @instances[instance_name] }
        end
      end

      def launch
        store_app_stack_metadata!
        @unlaunched_instances.each_pair do |instance_name, params|
          @instances[instance_name] = Awsymandias::Instance.launch(params)
          @instances[instance_name].name = instance_name
          @unlaunched_instances.delete instance_name
        end
        store_app_stack_metadata!
        @volumes.each do |volume, options|
          instance = @instances[options[:instance]]
          until instance.reload.running? 
            sleep(5)
          end
          instance.attach_volume(options[:volume_id], options[:unix_device])
        end
        self
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
  
        Awsymandias::SimpleDB.put @simpledb_domain, @name, metadata
      end

      def remove_app_stack_metadata!
        Awsymandias::SimpleDB.delete @simpledb_domain, @name
      end

      def reload_from_metadata!
        metadata = Awsymandias::SimpleDB.get @simpledb_domain, @name 
      
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
