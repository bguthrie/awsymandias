# Goal:
# stack = ApplicationStack.new do |stack|
#   stack.role "db", :instance_type => EC2::InstanceTypes::C1_XLARGE, :image_id => "ami-3576915c"
#   stack.role "app1", "app2", "app3", :instance_type => EC2::InstanceType::M1_XLARGE, :image_id => "ami-dc789fb5"
#   stack.role "memcache", :instance_type => EC2::InstanceType::C1_LARGE, :image_id => "ami-dc789fb5"
# end
# stack.app1.running?
module Awsymandias
  class ApplicationStack
    attr_reader :name, :roles, :sdb_domain, :unlaunched_instances, :instances

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
      opts.assert_valid_keys :roles, :sdb_domain

      @name       = name
      @sdb_domain = opts[:sdb_domain] || DEFAULT_SDB_DOMAIN
      @instances  = {}
      @unlaunched_instances = {}
      @roles = []

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
        @unlaunched_instances[instance_name] = nil
      end
      store_app_stack_metadata!
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
      output << "   Stack:  #{name}"
      @instances.each_pair do |instance_name, instance|
        output << "     #{instance_name}\t#{instance.instance_id}\t#{instance.aws_state}\t#{instance.aws_availability_zone}\t#{instance.aws_instance_type.name}\t#{instance.aws_image_id}\tLaunched #{instance.aws_launch_time}"
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
                                                :attached_volumes => instance.attached_volumes.map { |vol| vol[:aws_id] }
                                              }
      end          
  
      metadata.each_pair { |key, value| metadata[key] = Marshal.dump(value) }
 
      Awsymandias::SimpleDB.put @sdb_domain, @name, metadata
    end

    def remove_app_stack_metadata!
      Awsymandias::SimpleDB.delete @sdb_domain, @name
    end

    def reload_from_metadata!
      metadata = Awsymandias::SimpleDB.get @sdb_domain, @name 
      
      unless metadata.empty?
        metadata.keys.each { |key| metadata[key.to_sym] = Marshal.load( Base64.decode64( metadata.delete(key).first ) ) }
        
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
