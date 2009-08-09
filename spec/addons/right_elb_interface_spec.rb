require 'rubygems'
require 'spec'
require File.expand_path(File.dirname(__FILE__) + "/../../lib/awsymandias")

if !"".respond_to?(:camelize)
  class String 
    def camelize(first_letter = :upper)
      case first_letter
        when :upper 
          self.to_s.gsub(/\/(.?)/) { "::" + $1.upcase }.gsub(/(^|_)(.)/) { $2.upcase }
        when :lower 
          self.first + camelize(lower_case_and_underscored_word)[1..-1]
      end
    end
  end
end

module RightAws
  describe ElbInterface do
    describe "rehash_params_for_request" do
      it "returns properly formatted request params" do
        starting_params = {:load_balancer_name => 'Bob', 
                           :some_hash => {:key => 'val'},
                           :some_array => ['array_val_1', 'array_val_2'],
                           :some_array_of_hashes => [ { :key1 => 'val1',
                                                        :key2 => 'val2' },
                                                      { :key3 => 'val3',
                                                        :key4 => 'val4' },
                                                    ]
                          }
        expected_params =  {"LoadBalancerName"               => "Bob",
                           "SomeHash.Key"                    => "val",
                           "SomeArray.member.1"              => "array_val_1",
                           "SomeArray.member.2"              => "array_val_2",
                           "SomeArrayOfHashes.member.1.Key1" => "val1",
                           "SomeArrayOfHashes.member.1.Key2" => "val2",
                           "SomeArrayOfHashes.member.2.Key3" => "val3",
                           "SomeArrayOfHashes.member.2.Key4" => "val4"}
                         
        elb = ElbInterface.new(:some_key, :some_secret_key)
        elb.send(:rehash_params_for_request,starting_params).should == expected_params
      end
    end
  end
end