module Awsymandias
  class StackDefinition
    attr_reader :name, :defined_instances, :defined_volumes, :defined_roles
    
    def initialize(name)
      @name = name
      @defined_instances = {}
      @defined_volumes = {}
      @defined_roles = {}
    end
 
    def instance(name, config={})
      extract_roles(config).each { |r| role(r, name) }
      @defined_instances[name] = config
    end
    
    def instances(*names)
      config = names.extract_options!
      roles = extract_roles(config)
      names.each do |name| 
        roles.each { |r| role(r, name) }
        instance(name, config) 
      end
    end
    
    def role(name, *instance_names)
      @defined_roles[name] ||= []
      @defined_roles[name] += instance_names
    end
    
    def volume(name, configuration={})
      @defined_volumes[name] = configuration
    end
    
    def volumes(*names)
      configuration = names.extract_options!
      names.each { |name| volume(name, configuration) }
    end
   
    def build_stack
      Awsymandias::EC2::ApplicationStack.new(name, 
        :instances => defined_instances,
        :volumes => defined_volumes,
        :roles => defined_roles
      )
    end
    
    private
    def extract_roles(config)
      [config.delete(:roles), config.delete(:role)].flatten.compact
    end
    
  end
end