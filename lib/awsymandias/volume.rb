module Awsymandias
  class Volume < ActiveResource::Base
    hash_initializer :aws_size, :aws_device, :aws_attachment_status, :zone, :snapshot_id, :aws_attached_at, :aws_status, :aws_id, :aws_created_at, :aws_instance_id, :stack
    attr_reader :aws_size, :aws_device, :aws_attachment_status, :zone, :snapshot_id, :aws_attached_at, :aws_status, :aws_id, :aws_created_at, :aws_instance_id
    
    def id;        @aws_id; end
    def volume_id; @aws_id; end
    
  end
end