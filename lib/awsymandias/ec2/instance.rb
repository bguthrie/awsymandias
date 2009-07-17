# An instance represents an AWS instance as derived from a call to EC2's describe-instances methods.
# It wraps the simple hash structures returned by the EC2 gem with a domain model.
# It inherits from ARes::B in order to provide simple XML <-> domain model mapping.
module Awsymandias
  module EC2
    class Instance < ActiveResource::Base
      include Awsymandias::Support::Hash
      extend  Awsymandias::Support::Hash # reformat_incoming_param_data

      self.site = "mu"

      def id;          instance_id;      end
      def public_dns;  dns_name;         end
      def private_dns; private_dns_name; end

      def pending?
        instance_state.name == "pending"
      end

      def running?
        instance_state.name == "running"
      end

      def port_open?(port)
        Net::Telnet.new("Host" => public_dns, "Port" => port) && true rescue false
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
    end
  end
end
