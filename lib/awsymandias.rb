unless defined?(Awsymandias)
  Dir[File.dirname(__FILE__) + "/../vendor/**/lib"].each { |dir| $: << dir }

  require 'EC2'
  require 'right_aws'
  require 'aws_sdb'
  require 'money'
  require 'activesupport'
  require 'activeresource'
  require 'net/telnet'

  require File.dirname(__FILE__) + "/awsymandias/support"
  Dir[File.dirname(__FILE__) + "/awsymandias/**/*.rb"].each { |file| require file }

  module Awsymandias
  
    class << self
      attr_writer :access_key_id, :secret_access_key
      attr_accessor :verbose
    
      Awsymandias.verbose = false
    
      def access_key_id
        @access_key_id || AMAZON_ACCESS_KEY_ID || ENV['AMAZON_ACCESS_KEY_ID'] 
      end
    
      def secret_access_key
        @secret_access_key || AMAZON_SECRET_ACCESS_KEY || ENV['AMAZON_SECRET_ACCESS_KEY']
      end
    
      def stack_names
        Awsymandias::SimpleDB.connection.query('application-stack', "").flatten.select { |stack_name| !stack_name.blank? }
      end
    
      def wait_for(message, refresh_seconds, &block)
        print "Waiting for #{message}.." if Awsymandias.verbose
        while !block.call
          print "." if Awsymandias.verbose
          sleep(refresh_seconds)      
        end
        verbose_output "OK!"
      end
    
      def verbose_output(message)
        puts message if Awsymandias.verbose
      end
    end
  end
end