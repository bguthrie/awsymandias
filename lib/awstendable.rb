require 'EC2'
require 'aws/s3'
require 'aws_sdb'
require 'activesupport'
require 'activeresource'

module Awstendable
  class << self
    attr_writer :access_key_id, :secret_access_key
    
    def access_key_id
      @access_key_id || AMAZON_ACCESS_KEY_ID || ENV['AMAZON_ACCESS_KEY_ID'] 
    end
    
    def secret_access_key
      @secret_access_key || AMAZON_SECRET_ACCESS_KEY || ENV['AMAZON_SECRET_ACCESS_KEY']
    end
  end
  
  module EC2
    class << self
      # Define the values for AMAZON_ACCESS_KEY_ID and AMAZON_SECRET_ACCESS_KEY_ID to allow for automatic
      # connection creation.
      def connection
        @connection ||= ::EC2::Base.new(
          :access_key_id     => Awstendable.access_key_id     || ENV['AMAZON_ACCESS_KEY_ID'],
          :secret_access_key => Awstendable.secret_access_key || ENV['AMAZON_SECRET_ACCESS_KEY']
        )
      end
      
      def reset_connection
        @connection = nil
      end      
    end
    
    # All currently available instance times.
    # TODO Generate dynamically.
    module InstanceTypes
      M1_SMALL = "m1.small"
      M1_LARGE = "m1.large"
      M1_XLARGE = "m1.xlarge"
    
      C1_MEDIUM = "c1.medium"
      C1_XLARGE = "c1.xlarge"
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
      include ActiveSupport::CoreExtensions::Hash::Conversions::ClassMethods 
      extend  ActiveSupport::CoreExtensions::Hash::Conversions::ClassMethods # unrename_keys
    
      self.site = "mu"
    
      def id;          instance_id;      end
      def public_dns;  dns_name;         end
      def private_dns; private_dns_name; end
    
      def running?
        instance_state.name == "running"
      end
    
      def terminated?
        instance_state.name == "terminated"
      end
    
      def terminate!
        Awstendable::EC2.connection.terminate_instances :instance_id => self.instance_id
        reload
      end
    
      def reload
        load(unrename_keys(
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
            reservation_set["item"].first["instancesSet"]["item"].map do |item|
              instantiate_record(unrename_keys(item))
            end
          end
        end
        
        def find_one(id, opts={})
          reservation_set = EC2.connection.describe_instances(:instance_id => [ id ])["reservationSet"]
          if reservation_set.nil?
            raise ActiveResource::ResourceNotFound, "not found: #{id}"
          else
            reservation_set["item"].first["instancesSet"]["item"].map do |item|
              instantiate_record(unrename_keys(item))
            end.first
          end
        end
      
        def launch(opts={})
          opts.assert_valid_keys! :image_id, :key_name, :instance_type, :availability_zone
        
          opts[:user_data] &&= opts[:user_data].to_json
        
          response = Awstendable::EC2.connection.run_instances opts
          instance_id = response["instancesSet"]["item"].map {|h| h["instanceId"]}.first
          find(instance_id)
        end
      end
    end
  
    # A class designed to provide simple Rake task generation for launching EC2 instances.
    class InstanceLaunchTask
      attr_accessor :ami_id, :instance_type, :availability_zone, :key_name
    
      def initialize(name, desc="Spin up a new EC2 instance")
        @name, @desc = name, desc
        yield self
        define
      end
    
      def define
        desc @desc
        task @name do
          EC2::Instance.launch(
            :ami_id => ami_id, 
            :instance_type => instance_type, 
            :availability_zone => availability_zone, 
            :key_name => key_name
          )
        
          puts "Instance ID is #{instance.id}"
        end
      
        desc "#{@desc} (waits for startup)"
        task "#{@name}_blocked" do
          instance = EC2::Instance.launch(
            :ami_id => ami_id, 
            :instance_type => instance_type, 
            :availability_zone => availability_zone, 
            :key_name => key_name
          )
        
          until instance.reload.running?
            sleep(5)
          end
        
          puts "Instance ID is #{instance.id}, public DNS is #{instance.dns_name}, private DNS is #{instance.private_dns_name}"
        end
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
          @instances[name] = Awstendable::EC2::Instance.launch(params)
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
        @instances.any? || restore_from_role_to_instance_id_mapping.any?
      end
          
      def running?
        launched? && @instances.values.all?(&:running?)
      end
      
      def inspect
        ( [ "Environment #{@name}, running? #{running?}" ] + roles.map do |role_name, opts|
          "** #{role_name}: #{opts.inspect}"
        end ).join("\n")
      end
      
      private
            
        def role_names
          @roles.keys
        end
              
        def store_role_to_instance_id_mapping!
          Awstendable::SimpleDB.put @sdb_domain, @name, ( returning({}) do |h|
            @instances.each {|role_name, instance| h[role_name] = instance.instance_id}
          end )
        end
        
        def remove_role_to_instance_id_mapping!
          Awstendable::SimpleDB.delete @sdb_domain, @name
        end
        
        def restore_from_role_to_instance_id_mapping
          @instances = returning(Awstendable::SimpleDB.get(@sdb_domain, @name)) do |mapping|
            unless mapping.empty?
              live_instances = Awstendable::EC2::Instance.find(:all, :instance_ids => mapping.values.flatten).index_by(&:instance_id)
              mapping.each do |role_name, instance_id|
                mapping[role_name] = live_instances[instance_id.first]
              end
            end
          end
        end
        
        def create_domain_if_necessary
          unless Awstendable::SimpleDB.connection.list_domains[0].include?(@sdb_domain)
            Awstendable::SimpleDB.connection.create_domain(@sdb_domain)
          end
        end
    end
  end
      
  module S3
    module DefaultConnection
      def connection_with_defaults(*args)
        retried = false
        connection_without_defaults(*args)
      rescue AWS::S3::NoConnectionEstablished
        establish_connection!(
          :access_key_id     => ENV['AMAZON_ACCESS_KEY_ID'],
          :secret_access_key => ENV['AMAZON_SECRET_ACCESS_KEY']
        )
        retried ? raise : ( retried = true; retry )
      end
    end
    
    AWS::S3::Base.send :extend, DefaultConnection
    AWS::S3::Base.metaclass.send :alias_method_chain, :connection, :defaults
  end

  # TODO Locate a nicer SimpleDB API and get out of the business of maintaining this one.
  module SimpleDB # :nodoc
    class << self
      def connection(opts={})
        @connection ||= ::AwsSdb::Service.new({
          :access_key_id     => Awstendable.access_key_id     || ENV['AMAZON_ACCESS_KEY_ID'],
          :secret_access_key => Awstendable.secret_access_key || ENV['AMAZON_SECRET_ACCESS_KEY']
        }.merge(opts))
      end
      
      def reset_connection
        @connection = nil
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
          Awstendable::SimpleDB.connection.list_domains[0].include?(domain)
        end      
      
        def handle_domain(domain)
          returning(domain) { connection.create_domain(domain) unless domain_exists?(domain) }
        end
    end
  end
end
