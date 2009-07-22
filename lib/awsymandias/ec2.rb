module Awsymandias
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
  
  end  
end