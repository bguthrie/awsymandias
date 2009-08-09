#
# Copyright (c) 2008 RightScale Inc
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#

require "right_aws"

module RightAws

  class ElbInterface < RightAwsBase
    
    include RightAwsBaseInterface

    DEFAULT_HOST      = 'elasticloadbalancing.amazonaws.com'
    DEFAULT_PORT      = 443
    DEFAULT_PROTOCOL  = 'https'
    API_VERSION       = '2009-05-15'
    DEFAULT_NIL_REPRESENTATION = 'nil'

    @@bench = AwsBenchmarkingBlock.new
    def self.bench_xml; @@bench.xml;     end
    def self.bench_elb; @@bench.service; end

    attr_reader :last_query_expression

    def on_exception
      super
    rescue RightAws::AwsError => e
      error = Hash.from_xml(last_response.body)['ErrorResponse']['Error']
      raise RightAws::AwsError, "#{error['Code']}:  #{error['Message']}"
    end

    # Creates new RightElb instance.
    #
    # Params:
    #    { :server       => 'elasticloadbalancing.amazonaws.com'  
    #      :port         => 443                  # Amazon service port: 80 or 443(default)
    #      :protocol     => 'https'              # Amazon service protocol: 'http' or 'https'(default)
    #      :signature_version => '0'             # The signature version : '0' or '1'(default)
    #      :multi_thread => true|false           # Multi-threaded (connection per each thread): true or false(default)
    #      :logger       => Logger Object        # Logger instance: logs to STDOUT if omitted 
    #      :nil_representation => 'mynil'}       # interpret Ruby nil as this string value; i.e. use this string in SDB to represent Ruby nils (default is the string 'nil')
    #      
    # Example:
    # 
    #  elb = RightAws::ElbInterface.new('1E3GDYEOGFJPIT7XXXXXX','hgTHt68JY07JKUY08ftHYtERkjgtfERn57XXXXXX', {:multi_thread => true, :logger => Logger.new('/tmp/x.log')}) #=> #<RightElb:0xa6b8c27c>
    #  
    # see: http://docs.amazonwebservices.com/AmazonSimpleDB/2007-11-07/DeveloperGuide/
    #
    def initialize(aws_access_key_id=nil, aws_secret_access_key=nil, params={})
      @nil_rep = params[:nil_representation] ? params[:nil_representation] : DEFAULT_NIL_REPRESENTATION
      params.delete(:nil_representation)
      init({ :name             => 'ELB', 
             :default_host     => ENV['ELB_URL'] ? URI.parse(ENV['ELB_URL']).host   : DEFAULT_HOST, 
             :default_port     => ENV['ELB_URL'] ? URI.parse(ENV['ELB_URL']).port   : DEFAULT_PORT, 
             :default_protocol => ENV['ELB_URL'] ? URI.parse(ENV['ELB_URL']).scheme : DEFAULT_PROTOCOL }, 
           aws_access_key_id     || ENV['AWS_ACCESS_KEY_ID'], 
           aws_secret_access_key || ENV['AWS_SECRET_ACCESS_KEY'], 
           params)
    end
    
    #-----------------------------------------------------------------
    #      API METHODS:
    #-----------------------------------------------------------------

    # elb.configure_health_check lb_name, {:healthy_threshold=>10, :unhealthy_threshold=>3, 
    #                                       :target=>"TCP:3081", :interval=>31, :timeout=>6}
    # => {:healthy_threshold=>"10", :unhealthy_threshold=>"3", :interval=>"31", :target=>"TCP:3081", :timeout=>"6"}    
    def configure_health_check(lb_name, health_check)
      link = generate_request("ConfigureHealthCheck",
                              :load_balancer_name => lb_name, :health_check => health_check)
      request_info(link, QElbConfigureHealthCheckParser.new)
    rescue Exception
      on_exception
    end

     # elb.create_lb lb_name, ['us-east-1b'], [{:load_balancer_port=>80, :instance_port=>3080, :protocol=>"HTTP"},
     #                                          {:load_balancer_port=>8080, :instance_port=>3081, :protocol=>"HTTP"}]
     # => {:dns_name=>"RobTest-883635706.us-east-1.elb.amazonaws.com"}
    def create_lb(lb_name, availability_zones, listeners)     
      link = generate_request("CreateLoadBalancer",
                              :load_balancer_name => lb_name,
                              :availability_zones => availability_zones,
                              :listeners => listeners
                             )
      request_info(link, QElbSimpleParser.new(['DNSName']))
    rescue Exception
      on_exception
    end

    # elb.delete_lb lb_name
    # => {}
    def delete_lb(lb_name)
      link = generate_request("DeleteLoadBalancer",
                              :load_balancer_name => lb_name)
      request_info(link, QElbSimpleParser.new)
    rescue Exception
      on_exception
    end

    # elb.deregister_instances_from_lb lb_name, "i-5552453c"
    # => ["i-5752453e"]
    def deregister_instances_from_lb(lb_name, instance_ids)
      instances = instance_ids.map { |instance_id| { :instance_id => instance_id } }
      link = generate_request("DeregisterInstancesFromLoadBalancer",
                              :load_balancer_name => lb_name, :instances => instances
                             )
      request_info(link, QElbInstancesParser.new)
    rescue Exception
      on_exception
    end

     # elb.describe_lbs
     # => [{:aws_created_at=>Tue Aug 04 11:14:27 UTC 2009,
     #      :availability_zones=>["us-east-1b"],
     #      :dns_name=>"RobTest-883635706.us-east-1.elb.amazonaws.com",
     #      :name=>"RobTest",
     #      :instances=>["i-5752453e"],
     #      :listeners=> [{:protocol=>"HTTP", :load_balancer_port=>80, :instance_port=>3080},
     #                    {:protocol=>"HTTP", :load_balancer_port=>8080, :instance_port=>3081}
     #                   ],
     #      :health_check=> { :healthy_threshold=>10,
     #                        :unhealthy_threshold=>3,
     #                        :interval=>31,
     #                        :target=>"TCP:3081",
     #                        :timeout=>6
     #                      }
     #    }]
    def describe_lbs(lb_names = nil)
      link = generate_request("DescribeLoadBalancers",
                              :load_balancer_names => lb_names)
      request_info(link, QElbDescribeLbsParser.new)
    rescue Exception
      on_exception
    end

    # elb.describe_instance_health lb_name
    # => {"i-5752453e"=>{:description=>"Instance registration is still in progress.", 
    #                    :reason_code=>"ELB", 
    #                    :state=>"OutOfService"}}
    def describe_instance_health(lb_name, instances = nil)
      link = generate_request("DescribeInstanceHealth", :load_balancer_name => lb_name, :instances => instances)
      request_info(link, QElbDescribeInstanceHealthParser.new)
    rescue Exception
      on_exception
    end

    # elb.disable_availability_zones_for_lb lb_name, ['us-east-1c']
    # => ["us-east-1b", "us-east-1a"]
    def disable_availability_zones_for_lb(lb_name, availability_zones)
      link = generate_request("DisableAvailabilityZonesForLoadBalancer",
                              :load_balancer_name => lb_name, :availability_zones => availability_zones)
      request_info(link, QElbAvailabilityZonesParser.new)
    rescue Exception
      on_exception
    end

    # elb.enable_availability_zones_for_lb lb_name, ['us-east-1a', 'us-east-1c']
    # => ["us-east-1b", "us-east-1c", "us-east-1a"]
    def enable_availability_zones_for_lb(lb_name, availability_zones)
      link = generate_request("EnableAvailabilityZonesForLoadBalancer",
                              :load_balancer_name => lb_name, :availability_zones => availability_zones)
      request_info(link, QElbAvailabilityZonesParser.new)
    rescue Exception
      on_exception
    end

    # elb.register_instances_with_lb lb_name, ["i-5552453c", "i-5752453e"]
    # => ["i-5552453c", "i-5752453e"]
    def register_instances_with_lb(lb_name, instance_ids)
      instances = instance_ids.map { |instance_id| { :instance_id => instance_id } }
      link = generate_request("RegisterInstancesWithLoadBalancer",
                              :load_balancer_name => lb_name, :instances => instances)
      request_info(link, QElbInstancesParser.new)
    rescue Exception
      on_exception
    end


    private

    #-----------------------------------------------------------------
    #      Requests
    #-----------------------------------------------------------------
    def generate_request(action, params={}) #:nodoc:
      # remove empty params from request
      params.delete_if {|key,value| value.nil? }
      params = rehash_params_for_request(params)

      # prepare service data
      service = '/'
      service_hash = {"Action"         => action,
                      "AWSAccessKeyId" => @aws_access_key_id,
                      "Version"        => API_VERSION }
      service_hash.update(params)
      service_params = signed_service_params(@aws_secret_access_key, service_hash, :get, @params[:server], service)
      #
      request = Net::HTTP::Get.new("#{service}?#{service_params}")

      # prepare output hash
      { :request  => request, 
        :server   => @params[:server],
        :port     => @params[:port],
        :protocol => @params[:protocol] }
    end

    # Sends request to Amazon and parses the response
    # Raises AwsError if any banana happened
    def request_info(request, parser)  #:nodoc:
      thread = @params[:multi_thread] ? Thread.current : Thread.main
      thread[:elb_connection] ||= Rightscale::HttpConnection.new(:exception => AwsError, :logger => @logger)
      request_info_impl(thread[:elb_connection], @@bench, request, parser)
    end
        
    def rehash_params_for_request(parameters = {})
      new_params = {}
      parameters.each_pair do |param_name, value|
        case value.class.name
          when 'Array'
            value.each_with_index do |element, index| 
              if element.is_a? Hash
                element.each_pair do |key, val| 
                  new_params["#{param_name.to_s.camelize}.member.#{index + 1}.#{key.to_s.camelize}"] = val 
                end
              else
                new_params["#{param_name.to_s.camelize}.member.#{index + 1}"] = element 
              end
            end
          when 'Hash'
            value.each_pair do |key, val|
              new_params["#{param_name.to_s.camelize}.#{key.to_s.camelize}"] = val
            end
          else
            new_params[param_name.to_s.camelize] = value
        end
      end
      new_params
    end
      
    #-----------------------------------------------------------------
    #      PARSERS:
    #-----------------------------------------------------------------
    class QElbDescribeLbsParser < RightAWSParser #:nodoc:
      def tagstart(name, attributes)
        case name
        when 'HealthCheck' then @health_check = {}
        when 'member'
          case @xmlpath
            when 'DescribeLoadBalancersResponse/DescribeLoadBalancersResult/LoadBalancerDescriptions' then @lb = {:listeners => [], :availability_zones => [], :instances => []}
            when 'DescribeLoadBalancersResponse/DescribeLoadBalancersResult/LoadBalancerDescriptions/member/Listeners' then @listener = {}
            when 'DescribeLoadBalancersResponse/DescribeLoadBalancersResult/LoadBalancerDescriptions/member/Instances' then @instance = {}
          end
        end
      end
      def tagend(name)
        case name 
          when 'LoadBalancerName' then @lb[:name]            = @text
          when 'CreatedTime'      then @lb[:aws_created_at]  = Time.parse(@text)
          when 'DNSName'          then @lb[:dns_name]        = @text
            
          when 'Protocol'         then @listener[:protocol]  = @text
          when 'LoadBalancerPort' then @listener[:load_balancer_port]   = @text.to_i
          when 'InstancePort'     then @listener[:instance_port] = @text.to_i
            
          when 'HealthCheck'        then @lb[:health_check] = @health_check
          when 'Interval'           then @health_check[:interval] = @text.to_i
          when 'Target'             then @health_check[:target] = @text
          when 'HealthyThreshold'   then @health_check[:healthy_threshold] = @text.to_i
          when 'Timeout'            then @health_check[:timeout] = @text.to_i
          when 'UnhealthyThreshold' then @health_check[:unhealthy_threshold] = @text.to_i
            
          when 'member' 
            case @xmlpath
              when 'DescribeLoadBalancersResponse/DescribeLoadBalancersResult/LoadBalancerDescriptions' then @result << @lb
              when 'DescribeLoadBalancersResponse/DescribeLoadBalancersResult/LoadBalancerDescriptions/member/Listeners' then @lb[:listeners] << @listener
              when 'DescribeLoadBalancersResponse/DescribeLoadBalancersResult/LoadBalancerDescriptions/member/Listeners' then @lb[:instances] << @instance
              when 'DescribeLoadBalancersResponse/DescribeLoadBalancersResult/LoadBalancerDescriptions/member/AvailabilityZones' then @lb[:availability_zones] << @text
              when 'DescribeLoadBalancersResponse/DescribeLoadBalancersResult/LoadBalancerDescriptions/member/Instances' then @lb[:instances] << @text.strip
            end
        end
      end
      def reset
        @result = []
      end
    end

    class QElbDescribeInstanceHealthParser < RightAWSParser #:nodoc:
      def reset
        @result = {}
      end
      def tagstart(name, attributes)
        @instance_health = {} if name == 'member'
      end
      def tagend(name)
        case name 
          when 'Description' then @instance_health[:description] = @text
          when 'State'       then @instance_health[:state]       = @text
          when 'ReasonCode'  then @instance_health[:reason_code] = @text        
          when 'InstanceId'  then @instance_id = @text
        
          when 'member' then @result[@instance_id] = @instance_health
        end
      end
    end
    
    class QElbConfigureHealthCheckParser < RightAWSParser #:nodoc:
      def reset
        @result = {}
      end
      def tagstart(name, attributes)
        case name
          when 'ConfigureHealthCheckResult' then @healthcheck = {}
        end
      end
      def tagend(name)
        case name
          when 'ConfigureHealthCheckResult'  then @result = @healthcheck
          when 'HealthyThreshold', 'UnhealthyThreshold', 'Target', 'Interval', 'Timeout' 
            @healthcheck[name.underscore.to_sym] = @text
        end
      end
    end

    class QElbAvailabilityZonesParser < RightAWSParser #:nodoc:
      def reset
        @result = []
      end
      def tagend(name)
        @result << @text if name == 'member'
      end
    end

    class QElbInstancesParser < RightAWSParser #:nodoc:
      def reset
        @result = []
      end
      def tagend(name)
        @result << @text if name == 'InstanceId'
      end
    end

    class QElbSimpleParser < RightAWSParser #:nodoc:
      def initialize(names_to_parse = ['InstanceId'])
        super()
        @names_to_parse = names_to_parse
      end
      def reset
        @result = {}
      end
      def tagend(name)
        @result[name.underscore.to_sym] = @text if @names_to_parse.include?(name)
      end
    end

  end
  
end
