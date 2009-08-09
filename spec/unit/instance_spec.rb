require 'rubygems'
require 'spec'
require File.expand_path(File.dirname(__FILE__) + "/../../lib/awsymandias")

module Awsymandias
  module RightAws
    describe Instance do
      def stub_connection_with(requested, return_value)
        Awsymandias::RightAws.stub!(:connection).and_return stub("a connection", requested.to_sym => return_value)
      end
  
      DESCRIBE_INSTANCES_NO_RESULTS_RESPONSE = []

      DESCRIBE_INSTANCES_SINGLE_RESULT_PENDING_RESPONSE = [{:aws_instance_type=>"m1.large",
                                                            :ami_launch_index=>"0",
                                                            :aws_reason=>"",
                                                            :aws_launch_time=>"2009-04-20T01:30:35.000Z",
                                                            :aws_owner=>"423319072129",
                                                            :ssh_key_name=>"",
                                                            :aws_reservation_id=>"r-b9b6e2d0",
                                                            :aws_kernel_id=>"aki-b51cf9dc",
                                                            :aws_instance_id=>"i-pending-instance",
                                                            :aws_availability_zone=>"us-east-1b",
                                                            :aws_state=>"pending",
                                                            :aws_groups=>["default"],
                                                            :aws_ramdisk_id=>"ari-b31cf9da",
                                                            :aws_image_id=>"ami-890beae0",
                                                            :dns_name=>"",
                                                            :aws_state_code=>"0",
                                                            :aws_product_codes=>[],
                                                            :private_dns_name=>""}]

      DESCRIBE_INSTANCES_SINGLE_RESULT_RUNNING_RESPONSE = [{:aws_instance_type=>"m1.large",
                                                            :ami_launch_index=>"0",
                                                            :aws_reason=>"",
                                                            :aws_launch_time=>"2009-07-23T13:57:22.000Z",
                                                            :aws_owner=>"423319072129",
                                                            :ssh_key_name=>"gsg-keypair",
                                                            :aws_reservation_id=>"r-dd6733b4",
                                                            :aws_kernel_id=>"aki-b51cf9dc",
                                                            :aws_instance_id=>"i-single-running-instance",
                                                            :aws_availability_zone=>"us-east-1b",
                                                            :aws_state=>"running",
                                                            :aws_groups=>["default"],
                                                            :aws_ramdisk_id=>"ari-b31cf9da",
                                                            :aws_image_id=>"ami-some-image",
                                                            :dns_name=>"ec2-174-129-118-52.compute-1.amazonaws.com",
                                                            :aws_state_code=>"16",
                                                            :aws_product_codes=>[],
                                                            :private_dns_name=>"ip-10-244-226-239.ec2.internal"}]

      DESCRIBE_INSTANCES_MULTIPLE_RESULTS_RUNNING_RESPONSE = [{:aws_instance_type=>"c1.xlarge",
                                                                     :ami_launch_index=>"0",
                                                                     :aws_reason=>"",
                                                                     :aws_launch_time=>"2009-07-23T13:57:22.000Z",
                                                                     :aws_owner=>"423319072129",
                                                                     :ssh_key_name=>"",
                                                                     :aws_reservation_id=>"r-dd6733b4",
                                                                     :aws_kernel_id=>"aki-b51cf9dc",
                                                                     :aws_instance_id=>"i-multiple_running_1",
                                                                     :aws_availability_zone=>"us-east-1b",
                                                                     :aws_state=>"running",
                                                                     :aws_groups=>["default"],
                                                                     :aws_ramdisk_id=>"ari-b31cf9da",
                                                                     :aws_image_id=>"ami-890beae0",
                                                                     :dns_name=>"ec2-174-129-124-195.compute-1.amazonaws.com",
                                                                     :aws_state_code=>"16",
                                                                     :aws_product_codes=>[],
                                                                     :private_dns_name=>"ip-10-250-214-207.ec2.internal"},
                                                                    {:aws_instance_type=>"m1.large",
                                                                     :ami_launch_index=>"0",
                                                                     :aws_reason=>"",
                                                                     :aws_launch_time=>"2009-07-23T14:57:22.000Z",
                                                                     :aws_owner=>"423319072129",
                                                                     :ssh_key_name=>"",
                                                                     :aws_reservation_id=>"r-dd6733b5",
                                                                     :aws_kernel_id=>"aki-b51cf9dc",
                                                                     :aws_instance_id=>"i-multiple_running_2",
                                                                     :aws_availability_zone=>"us-east-1b",
                                                                     :aws_state=>"running",
                                                                     :aws_groups=>["default"],
                                                                     :aws_ramdisk_id=>"ari-b31cf9da",
                                                                     :aws_image_id=>"ami-890beae0",
                                                                     :dns_name=>"ec2-174-129-124-196.compute-1.amazonaws.com",
                                                                     :aws_state_code=>"16",
                                                                     :aws_product_codes=>[],
                                                                     :private_dns_name=>"ip-10-250-214-208.ec2.internal"}]
      
      RUN_INSTANCES_SINGLE_RESULT_RESPONSE = [{:aws_image_id       => "ami-e444444d",
                                               :aws_reason         => "",
                                               :aws_state_code     => "0",
                                               :aws_owner          => "000000000888",
                                               :aws_instance_id    => "i-123f1234",
                                               :aws_reservation_id => "r-aabbccdd",
                                               :aws_state          => "pending",
                                               :dns_name           => "",
                                               :ssh_key_name       => "my_awesome_key",
                                               :aws_groups         => ["my_awesome_group"],
                                               :private_dns_name   => "",
                                               :aws_instance_type  => "m1.large",
                                               :aws_launch_time    => "2008-1-1T00:00:00.000Z",
                                               :aws_ramdisk_id     => "ari-8605e0ef",
                                               :aws_kernel_id      => "aki-9905e0f0",
                                               :ami_launch_index   => "0",
                                               :aws_availability_zone => "us-east-1b"}]
      

      TERMINATE_INSTANCES_SINGLE_RESULT_RESPONSE = [{:aws_shutdown_state      => "shutting-down",
                                                     :aws_instance_id         => "i-f222222d",
                                                     :aws_shutdown_state_code => 32,
                                                     :aws_prev_state          => "running",
                                                     :aws_prev_state_code     => 16}]

      DESCRIBE_INSTANCES_SINGLE_RESULT_TERMINATED_RESPONSE = [{:aws_instance_type=>"c1.xlarge",
                                                               :ami_launch_index=>"0",
                                                               :aws_reason=>"User initiated ",
                                                               :aws_launch_time=>"2009-07-23T18:22:49.000Z",
                                                               :aws_owner=>"423319072129",
                                                               :ssh_key_name=>"",
                                                               :aws_reservation_id=>"r-b9b6e2d0",
                                                               :aws_kernel_id=>"aki-b51cf9dc",
                                                               :aws_instance_id=>"i-fb585992",
                                                               :aws_availability_zone=>"us-east-1b",
                                                               :aws_state=>"terminated",
                                                               :aws_groups=>["default"],
                                                               :aws_ramdisk_id=>"ari-b31cf9da",
                                                               :aws_image_id=>"ami-890beae0",
                                                               :dns_name=>"",
                                                               :aws_state_code=>"48",
                                                               :aws_product_codes=>[],
                                                               :private_dns_name=>""}]

      describe "find" do
        it "should raise ActiveResource::ResourceNotFound if the given instance ID is not found" do
          stub_connection_with :describe_instances, DESCRIBE_INSTANCES_NO_RESULTS_RESPONSE
          lambda do
            Instance.find("i-some-instance")
          end.should raise_error(ActiveResource::ResourceNotFound)
        end

        it "should return an object with the appropriate instance ID when an instance with the given ID is found" do
          stub_connection_with :describe_instances, DESCRIBE_INSTANCES_SINGLE_RESULT_RUNNING_RESPONSE
          Instance.find("i-single-running-instance").instance_id.should == "i-single-running-instance"
        end

        it "should return more than one object if multiple IDs are requested" do
          stub_connection_with :describe_instances, DESCRIBE_INSTANCES_MULTIPLE_RESULTS_RUNNING_RESPONSE
          Instance.find(:all, :instance_ids => ["i-multiple_running_1", "i-multiple_running_2"]).map do |instance|
            instance.instance_id
          end.should == ["i-multiple_running_1", "i-multiple_running_2"]
        end

        it "should map camelized XML properties to Ruby-friendly underscored method names" do
          stub_connection_with :describe_instances, DESCRIBE_INSTANCES_SINGLE_RESULT_RUNNING_RESPONSE
          instance = Instance.find("i-single-running-instance")
          instance.aws_image_id.should == "ami-some-image"
          instance.ssh_key_name.should == "gsg-keypair"
          instance.aws_instance_type.should == Awsymandias::EC2.instance_types["m1.large"]
          instance.aws_availability_zone.should == "us-east-1b"
        end
      end

      describe "to_params" do
        it "should be able to reproduce a reasonable set of its launch params as a hash" do
          stub_connection_with :describe_instances, DESCRIBE_INSTANCES_SINGLE_RESULT_RUNNING_RESPONSE
          Instance.find("i-some-instance").to_params.should == {
            :aws_image_id => "ami-some-image",
            :ssh_key_name => "gsg-keypair",
            :aws_instance_type => Awsymandias::EC2.instance_types["m1.large"],
            :aws_availability_zone => "us-east-1b"
          }
        end
      end

      describe "running?" do        
        it "should return false if it contains an instances set with the given instance ID and its state is pending" do
          stub_connection_with :describe_instances, DESCRIBE_INSTANCES_SINGLE_RESULT_PENDING_RESPONSE
          Instance.find("i-some-instance").should_not be_running
        end

        it "should return true if it contains an instances set with the given instance ID and its state is running" do
          stub_connection_with :describe_instances, DESCRIBE_INSTANCES_SINGLE_RESULT_RUNNING_RESPONSE
          Instance.find("i-some-instance").should be_running
        end
      end

      describe "reload" do
        it "should reload an instance without replacing the object" do
          stub_connection_with :describe_instances, DESCRIBE_INSTANCES_SINGLE_RESULT_PENDING_RESPONSE
          instance = Instance.find("i-some-instance")
          instance.should_not be_running

          stub_connection_with :describe_instances, DESCRIBE_INSTANCES_SINGLE_RESULT_RUNNING_RESPONSE
          instance.reload.should be_running
        end    
      end

      describe "launch" do
        it "should launch a new instance given some values" do
          mock_connection = mock("a connection")
          mock_connection.should_receive(:run_instances).
            with("an_id", 1, 1, "default", "gsg-keypair", nil, nil, "m1.small", nil, nil, 
              "us_east_1a", nil).and_return(RUN_INSTANCES_SINGLE_RESULT_RESPONSE)

          mock_connection.should_receive(:describe_instances).and_return(DESCRIBE_INSTANCES_SINGLE_RESULT_PENDING_RESPONSE)

          Awsymandias::RightAws.stub!(:connection).and_return mock_connection

          Awsymandias::Instance.launch(
            :image_id => "an_id",
            :key_name => "gsg-keypair",
            :instance_type => Awsymandias::EC2::InstanceTypes::M1_SMALL,
            :availability_zone => Awsymandias::EC2::AvailabilityZones::US_EAST_1A        
          )
        end

        it "should convert the instance type it's given to a string as needed" do
          mock_connection = mock("a connection")
          mock_connection.should_receive(:run_instances).with(nil, 1, 1, "default", nil, nil, nil, 
            "m1.small", nil, nil, nil, nil).and_return(RUN_INSTANCES_SINGLE_RESULT_RESPONSE)
          mock_connection.should_receive(:describe_instances).and_return(stub("response").as_null_object)
          Awsymandias::RightAws.stub!(:connection).and_return mock_connection

          Awsymandias::Instance.launch(:instance_type => Awsymandias::EC2::InstanceTypes::M1_SMALL)
        end
      end

      describe "terminate!" do
        it "should terminate a running instance" do
          mock_connection = mock("a connection")
          mock_connection.should_receive(:describe_instances).and_return(
            DESCRIBE_INSTANCES_SINGLE_RESULT_RUNNING_RESPONSE,
            DESCRIBE_INSTANCES_SINGLE_RESULT_TERMINATED_RESPONSE
          )
          mock_connection.should_receive(:terminate_instances).and_return(
            TERMINATE_INSTANCES_SINGLE_RESULT_RESPONSE
          )

          Awsymandias::RightAws.stub!(:connection).and_return mock_connection

          instance = Awsymandias::Instance.find("a result id")
          instance.should be_running
          instance.terminate!
          instance.should_not be_running
          instance.should be_terminated
        end
      end

      describe "instance_type" do
        it "should return its instance_type attribute as an InstanceType object" do
          stub_connection_with :describe_instances, DESCRIBE_INSTANCES_SINGLE_RESULT_RUNNING_RESPONSE
          Instance.find("i-some-instance").aws_instance_type.should == Awsymandias::EC2::InstanceTypes::M1_LARGE
        end
      end

      describe "launch_time" do
        it "should return its launch_time attribute as an instance of Time" do
          stub_connection_with :describe_instances, DESCRIBE_INSTANCES_SINGLE_RESULT_PENDING_RESPONSE
          Awsymandias::Instance.find("i-some-instance").aws_launch_time.should == Time.parse("2009-04-20T01:30:35.000Z")
        end
      end

      describe "uptime" do
        it "should be zero seconds if it is not yet running" do
          stub_connection_with :describe_instances, DESCRIBE_INSTANCES_SINGLE_RESULT_PENDING_RESPONSE
          Awsymandias::Instance.find("i-some-instance").uptime.should == 0.seconds
        end

        it "should be zero seconds if it is terminated" do
          stub_connection_with :describe_instances, DESCRIBE_INSTANCES_SINGLE_RESULT_PENDING_RESPONSE
          Awsymandias::Instance.find("i-some-instance").uptime.should == 0.seconds
        end

        it "should calculate the uptime of a running instance in terms of its launch time" do
          time_now = Time.now
          Time.stub!(:now).and_return time_now
          stub_connection_with :describe_instances, DESCRIBE_INSTANCES_SINGLE_RESULT_RUNNING_RESPONSE
          instance = Awsymandias::Instance.find("i-some-instance")
          instance.uptime.should == (time_now - instance.aws_launch_time)
        end
      end

      describe "public_dns" do
        it "should return the public dns from the xml" do
          stub_connection_with :describe_instances, DESCRIBE_INSTANCES_SINGLE_RESULT_RUNNING_RESPONSE 
          Awsymandias::Instance.find("i-some-instance").public_dns.should == "ec2-174-129-118-52.compute-1.amazonaws.com"
        end
      end

      describe "private_dns" do
        it "should return the private dns from the xml" do
          stub_connection_with :describe_instances, DESCRIBE_INSTANCES_SINGLE_RESULT_RUNNING_RESPONSE 
          Awsymandias::Instance.find("i-some-instance").private_dns.should == "ip-10-244-226-239.ec2.internal"
        end
      end

      describe "running_cost" do
        it "should be zero if the instance has not yet been launched" do
          stub_connection_with :describe_instances, DESCRIBE_INSTANCES_SINGLE_RESULT_PENDING_RESPONSE
          Awsymandias::Instance.find("i-some-instance").running_cost.should == Money.new(0)
        end

        it "should be a single increment if the instance was launched 5 minutes ago" do
          stub_connection_with :describe_instances, DESCRIBE_INSTANCES_SINGLE_RESULT_RUNNING_RESPONSE
          instance = Awsymandias::Instance.find("i-some-instance")
          instance.attributes['aws_launch_time'] = 5.minutes.ago.to_s
          expected_cost = instance.aws_instance_type.price_per_hour
          instance.running_cost.should == expected_cost
        end

        it "should be a single increment if the instance was launched 59 minutes ago" do
          stub_connection_with :describe_instances, DESCRIBE_INSTANCES_SINGLE_RESULT_RUNNING_RESPONSE
          instance = Awsymandias::Instance.find("i-some-instance")
          instance.attributes['aws_launch_time'] = 59.minutes.ago.to_s
          expected_cost = instance.aws_instance_type.price_per_hour
          instance.running_cost.should == expected_cost
        end

        it "should be two increments if the instance was launched 61 minutes ago" do
          stub_connection_with :describe_instances, DESCRIBE_INSTANCES_SINGLE_RESULT_RUNNING_RESPONSE
          instance = Awsymandias::Instance.find("i-some-instance")
          instance.attributes['aws_launch_time'] = 61.minutes.ago.to_s
          expected_cost = instance.aws_instance_type.price_per_hour * 2
          instance.running_cost.should == expected_cost          
        end

        it "should be three increments if the instance was launched 150 minutes ago" do
          stub_connection_with :describe_instances, DESCRIBE_INSTANCES_SINGLE_RESULT_RUNNING_RESPONSE
          instance = Awsymandias::Instance.find("i-some-instance")
          instance.attributes['aws_launch_time'] = 150.minutes.ago.to_s
          expected_cost = instance.aws_instance_type.price_per_hour * 3
          instance.running_cost.should == expected_cost          
        end
      end

      describe "port_open?" do
        it "should return true if telnet does not raise" do
          stub_connection_with :describe_instances, DESCRIBE_INSTANCES_SINGLE_RESULT_RUNNING_RESPONSE
          instance = Awsymandias::Instance.find("i-some-instance")
          Net::Telnet.should_receive(:new).with("Timeout" => 5,
                                                "Host" => "ec2-174-129-118-52.compute-1.amazonaws.com",
                                                "Port" => 100).and_return(true)
          instance.port_open?(100).should be_true
        end

        it "should return false if telnet does raise" do
          stub_connection_with :describe_instances, DESCRIBE_INSTANCES_SINGLE_RESULT_RUNNING_RESPONSE
          instance = Awsymandias::Instance.find("i-some-instance")
          Net::Telnet.should_receive(:new).with("Timeout" => 5,
                                                "Host" => "ec2-174-129-118-52.compute-1.amazonaws.com",
                                                "Port" => 100).and_raise(Timeout::Error.new("error"))
          instance.port_open?(100).should be_false
        end
      end
      
      describe "dns_hostname" do
        it "should return instance name with dashes instead of underscores" do
          instance = Instance.new
          instance.name = :db_1
          instance.dns_hostname.should == "db-1"
        end
      end
    end
  end
end