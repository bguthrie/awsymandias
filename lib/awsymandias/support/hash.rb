module Awsymandias
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
end
