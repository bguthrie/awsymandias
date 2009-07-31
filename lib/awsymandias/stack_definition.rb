module Awsymandias
  module Context
    class StackDefinition
      attr_reader :defined_instances, :defined_volumes
      
      def initialize
        @defined_instances = {}
        @defined_volumes = {}
      end
   
      def instance(name, configuration={})
        @defined_instances[name] = configuration
      end
      
      def instances(*names)
        configuration = names.extract_options!
        names.each { |name| instance(name, configuration) }
      end
      
      def volume(name, configuration={})
        @defined_volumes[name] = configuration
      end
      
      def volumes(*names)
        configuration = names.extract_options!
        names.each { |name| volume(name, configuration) }
      end
      
    end
  end
end