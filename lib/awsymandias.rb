Dir[File.dirname(__FILE__) + "/../vendor/**/lib"].each { |dir| $: << dir }

require 'EC2'
require 'aws_sdb'
require 'money'
require 'activesupport'
require 'activeresource'
require 'net/telnet'

module Awsymandias
  class << self
    attr_writer :access_key_id, :secret_access_key
    
    def access_key_id
      @access_key_id || AMAZON_ACCESS_KEY_ID || ENV['AMAZON_ACCESS_KEY_ID'] 
    end
    
    def secret_access_key
      @secret_access_key || AMAZON_SECRET_ACCESS_KEY || ENV['AMAZON_SECRET_ACCESS_KEY']
    end
  end
  
  module Support
    module Hash
      # Ganked from ActiveResource 2.3.2.
      def reformat_incoming_param_data(params)
        case params.class.to_s
          when "Hash"
            params.inject({}) do |h,(k,v)|
              h[k.to_s.underscore.tr("-", "_")] = reformat_incoming_param_data(v)
              h
            end
          when "Array"
            params.map { |v| reformat_incoming_param_data(v) }
          else
            params
        end
      end
    end
  end
  
  module EC2
    class << self
      # Define the values for AMAZON_ACCESS_KEY_ID and AMAZON_SECRET_ACCESS_KEY_ID to allow for automatic
      # connection creation.
      def connection
        @connection ||= ::EC2::Base.new(
          :access_key_id     => Awsymandias.access_key_id     || ENV['AMAZON_ACCESS_KEY_ID'],
          :secret_access_key => Awsymandias.secret_access_key || ENV['AMAZON_SECRET_ACCESS_KEY']
        )
      end
      
      def instance_types
        [ 
          Awsymandias::EC2::InstanceTypes::M1_SMALL, 
          Awsymandias::EC2::InstanceTypes::M1_LARGE, 
          Awsymandias::EC2::InstanceTypes::M1_XLARGE, 
          Awsymandias::EC2::InstanceTypes::C1_MEDIUM, 
          Awsymandias::EC2::InstanceTypes::C1_XLARGE 
        ].index_by(&:name)
      end
    end
    
    InstanceType = Struct.new(:name, :price_per_hour)
    
    # All currently available instance types.
    # TODO Generate dynamically.
    module InstanceTypes
      M1_SMALL  = InstanceType.new("m1.small",  Money.new(10))
      M1_LARGE  = InstanceType.new("m1.large",  Money.new(40))
      M1_XLARGE = InstanceType.new("m1.xlarge", Money.new(80))

      C1_MEDIUM = InstanceType.new("c1.medium", Money.new(20))
      C1_XLARGE = InstanceType.new("c1.xlarge", Money.new(80))
    end
        
    # All currently availability zones.
    # TODO Generate dynamically.
    module AvailabilityZones
      US_EAST_1A = "us_east_1a"
      US_EAST_1B = "us_east_1b"
      US_EAST_1C = "us_east_1c"

      EU_WEST_1A = "eu_west_1a"
      EU_WEST_1B = "eu_west_1b"
    end
  
    # An instance represents an AWS instance as derived from a call to EC2's describe-instances methods.
    # It wraps the simple hash structures returned by the EC2 gem with a domain model.
    # It inherits from ARes::B in order to provide simple XML <-> domain model mapping.
    class Instance < ActiveResource::Base
      include Awsymandias::Support::Hash
      extend  Awsymandias::Support::Hash # reformat_incoming_param_data
      
      self.site = "mu"
    
      def id;          instance_id;      end
      def public_dns;  dns_name;         end
      def private_dns; private_dns_name; end

      def public_ip
        dns_to_ip(public_dns)
      end

      def private_ip
        dns_to_ip(private_dns)
      end
    
      def pending?
        instance_state.name == "pending"
      end
    
      def running?
        instance_state.name == "running"
      end
      
      def port_open?(port)
        begin
          Net::Telnet.new("Host" => public_dns, "Port" => port)
          true
        rescue Exception => e
          false
        end
      end
      
      def terminated?
        instance_state.name == "terminated"
      end
    
      def terminate!
        Awsymandias::EC2.connection.terminate_instances :instance_id => self.instance_id
        reload
      end
    
      def reload
        load(reformat_incoming_param_data(
          EC2.connection.describe_instances(:instance_id => [ self.instance_id ])["reservationSet"]["item"].
            first["instancesSet"]["item"].
            first # Good lord.
        ))
      end
      
      def to_params
        {
          :image_id => self.image_id,
          :key_name => self.key_name,
          :instance_type => self.instance_type,
          :availability_zone => self.placement.availability_zone
        }
      end
      
      def instance_type
        Awsymandias::EC2.instance_types[@attributes['instance_type']]
      end
      
      def launch_time
        Time.parse(@attributes['launch_time'])
      end
      
      def uptime
        return 0.seconds if pending?
        Time.now - self.launch_time
      end
      
      def running_cost
        return Money.new(0) if pending?
        instance_type.price_per_hour * (uptime / 1.hour).ceil 
      end
        
      class << self
        def find(*args)
          opts = args.extract_options!
          what = args.first
          
          if what == :all
            find_all(opts[:instance_ids], opts)
          else
            find_one(what, opts)
          end
        end
        
        def find_all(ids, opts={})
          reservation_set = EC2.connection.describe_instances(:instance_id => ids)["reservationSet"]
          if reservation_set.nil?
            []
          else
            reservation_set["item"].sum([]) do |item_set|
              item_set["instancesSet"]["item"].map do |item|
                instantiate_record(reformat_incoming_param_data(item))
              end
            end
          end
        end
        
        def find_one(id, opts={})
          reservation_set = EC2.connection.describe_instances(:instance_id => [ id ])["reservationSet"]
          if reservation_set.nil?
            raise ActiveResource::ResourceNotFound, "not found: #{id}"
          else
            reservation_set["item"].first["instancesSet"]["item"].map do |item|
              instantiate_record(reformat_incoming_param_data(item))
            end.first
          end
        end
      
        def launch(opts={})
          opts.assert_valid_keys! :image_id, :key_name, :instance_type, :availability_zone, :user_data
        
          opts[:instance_type] = opts[:instance_type].name if opts[:instance_type].is_a?(Awsymandias::EC2::InstanceType)
        
          response = Awsymandias::EC2.connection.run_instances opts
          instance_id = response["instancesSet"]["item"].map {|h| h["instanceId"]}.first
          find(instance_id)
        end
      end

      private

      def dns_to_ip(dns)
        match = dns.match(/(ec2|ip)-(\d+)-(\d+)-(\d+)-(\d+)/)
        match.captures[1..-1].join(".")
      end
    end
      
    # Goal:
    # stack = EC2::ApplicationStack.new do |stack|
    #   stack.role "db", :instance_type => EC2::InstanceTypes::C1_XLARGE, :image_id => "ami-3576915c"
    #   stack.role "app1", "app2", "app3", :instance_type => EC2::InstanceType::M1_XLARGE, :image_id => "ami-dc789fb5"
    #   stack.role "memcache", :instance_type => EC2::InstanceType::C1_LARGE, :image_id => "ami-dc789fb5"
    # end
    # stack.app1.running?
    class ApplicationStack
      attr_reader :name, :roles, :sdb_domain
      
      DEFAULT_SDB_DOMAIN = "application-stack"
      
      class << self
        def find(name)
          returning(new(name)) do |stack|
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
        opts.assert_valid_keys! :roles
        
        @name       = name
        @roles      = opts[:roles] || {}
        @sdb_domain = opts[:sdb_domain] || DEFAULT_SDB_DOMAIN
        @instances  = {}
        yield self if block_given?
      end
    
      def role(*names)
        opts = names.extract_options!
        names.each do |name|
          @roles[name] = opts
          self.metaclass.send(:define_method, name) { @instances[name] }
        end
      end
      
      def launch
        @roles.each do |name, params| # TODO Optimize this for a single remote call.
          @instances[name] = Awsymandias::EC2::Instance.launch(params)
        end
        store_role_to_instance_id_mapping!
        self
      end
          
      def reload
        raise "Can't reload unless launched" unless launched?
        @instances.values.each(&:reload) # TODO Optimize this for a single remote call.
        self
      end
          
      def terminate!
        @instances.values.each(&:terminate!) # TODO Optimize this for a single remote call.
        remove_role_to_instance_id_mapping!
        self
      end
      
      def launched?
        @instances.any? || ( @instances = retrieve_role_to_instance_id_mapping ).any?
      end
          
      def running?
        launched? && @instances.values.all?(&:running?)
      end
      
      def port_open?(port)
        @instances.values.all? { |instance| instance.port_open?(port) }
      end
      
      def running_cost
        return Money.new(0) unless launched?
        @instances.values.sum { |instance| instance.running_cost }
      end
      
      def inspect
        ( [ "Environment #{@name}, running? #{running?}" ] + roles.map do |role_name, opts|
          "** #{role_name}: #{opts.inspect}"
        end ).join("\n")
      end
      
      private
            
        def store_role_to_instance_id_mapping!
          Awsymandias::SimpleDB.put @sdb_domain, @name, ( returning({}) do |h|
            @instances.each {|role_name, instance| h[role_name] = instance.instance_id}
          end )
        end
        
        def remove_role_to_instance_id_mapping!
          Awsymandias::SimpleDB.delete @sdb_domain, @name
        end
        
        def retrieve_role_to_instance_id_mapping
          returning(Awsymandias::SimpleDB.get(@sdb_domain, @name)) do |mapping|
            unless mapping.empty?
              live_instances = Awsymandias::EC2::Instance.find(:all, :instance_ids => mapping.values.flatten).index_by(&:instance_id)
              mapping.each do |role_name, instance_id|
                mapping[role_name] = live_instances[instance_id.first]
              end
            end
          end
        end
        
    end
  end
      
  # TODO Locate a nicer SimpleDB API and get out of the business of maintaining this one.
  module SimpleDB # :nodoc
    class << self
      def connection(opts={})
        @connection ||= ::AwsSdb::Service.new({
          :access_key_id     => Awsymandias.access_key_id     || ENV['AMAZON_ACCESS_KEY_ID'],
          :secret_access_key => Awsymandias.secret_access_key || ENV['AMAZON_SECRET_ACCESS_KEY']
        }.merge(opts))
      end
      
      def put(domain, name, stuff)
        connection.put_attributes handle_domain(domain), name, stuff
      end
      
      def get(domain, name)
        connection.get_attributes(handle_domain(domain), name) || {}
      end
      
      def delete(domain, name)
        connection.delete_attributes handle_domain(domain), name
      end
            
      private
      
        def domain_exists?(domain)
          Awsymandias::SimpleDB.connection.list_domains[0].include?(domain)
        end      
      
        def handle_domain(domain)
          returning(domain) { connection.create_domain(domain) unless domain_exists?(domain) }
        end
    end
  end  
end
