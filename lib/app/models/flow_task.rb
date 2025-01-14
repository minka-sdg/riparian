class FlowTask < ActiveRecord::Base
  belongs_to :user
  
  # Input resources for the task, can be any model instance or file attachment
  has_many :inputs, class_name: "FlowTaskInput", dependent: :destroy, inverse_of: :flow_task
  
  # Output resources, generated by run method below
  has_many :outputs, class_name: "FlowTaskOutput", dependent: :destroy, inverse_of: :flow_task
  
  accepts_nested_attributes_for :inputs, :outputs
  
  validates_presence_of :inputs
  serialize :options
  
  def options
    super || {}
  end
  
  # This is the method called by DJ
  def perform
    update_attribute(:started_at, Time.now)
    if run
      update(finished_at: Time.now, error: nil)
    end
  end
  
  # Actual work should occur here.
  # This is just a stub.  Subclasses should make this method process the 
  # inputs and add outputs
  def run; end
  
  # Runs a system command with logging, captures STDIN, STDOUT, and STDERR and returns them
  def run_command(cmd)
    require 'open3'
    Rails.logger.info "[INFO #{Time.now}] #{self} running #{cmd}"
    update_attribute(:command, cmd)
    stdin, stdout, stderr = Open3.popen3(cmd)
    [stdin, stdout, stderr].map do |io|
      s = io.read.strip rescue nil
      io.close
      s
    end
  end
  
end
