module ClassExtension
  
  if !Class.respond_to?("hash_initializer")
    def hash_initializer(*attribute_names, &block)
      define_method(:initialize) do |*args|
        data = args.first || {}
        data.symbolize_keys!
        attribute_names.each do |attribute_name|
          instance_variable_set "@#{attribute_name}", data[attribute_name]
        end
        instance_eval &block if block
      end
    end
  end

end

Class.send :include, ClassExtension
