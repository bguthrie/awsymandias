module Awsymandias
  module RightElb
    class << self    
      def connection
        @connection ||= ::RightAws::ElbInterface.new(Awsymandias.access_key_id,  
                                                     Awsymandias.secret_access_key, 
                                                     {:logger => Logger.new("/dev/null")})
      end
      
      def describe_lbs(list = [])
        LoadBalancer.find(*list)
      end
      
    end
  end
end