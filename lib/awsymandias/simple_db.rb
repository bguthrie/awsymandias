# TODO Locate a nicer SimpleDB API and get out of the business of maintaining this one.
module Awsymandias
  module SimpleDB # :nodoc
    class << self
      def connection(opts={})
        @connection ||= ::AwsSdb::Service.new({
          :access_key_id     => Awsymandias.access_key_id     || ENV['AMAZON_ACCESS_KEY_ID'],
          :secret_access_key => Awsymandias.secret_access_key || ENV['AMAZON_SECRET_ACCESS_KEY'],
          :logger            => Logger.new("/dev/null")
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
