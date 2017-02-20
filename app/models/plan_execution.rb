require 'dop_common'
require 'dopv'
require 'dopi'
require 'log'

require 'fileutils'
require 'yaml'

class PlanExecution < ApplicationRecord

  enum status: [:new, :running, :done, :failed], _prefix: true

  valid_tasks = %w{setup run deploy undeploy teardown}

  validates :plan, presence: true, inclusion: {
    in: proc {|rec| plan_store.list },
    message: "The plan '%[value]' is not in the plan store",
  }
  validates :task, presence: true, inclusion: {
    in: valid_tasks,
    message: "Task '%{value}' is invalid. Valid tasks are: #{valid_tasks.join(', ')}",
  }

  serialize :run_options, Hash
  validates_each :run_options do |record, attr, value|
    next if value.nil?
    if value.kind_of?(Hash)
      if value.has_key?(:rmdisk)
        unless value[:rmdisk].in? [true, false]
          record.errors.add(:run_options, "the run_option 'rmdisk' has to be a boolean")
        end
      end
      if value.has_key?(:step_set)
        unless value[:step_set].in? list_step_sets(record.plan)
          record.errors.add(:run_options, "'#{value}' is not a valid step_set for the plan")
        end
      end
    else
      record.errors.add(:run_options, "run_options has to be a key value map")
    end
  end

  def self.log
    Delayed::Worker.logger
  end

  def self.log_dir
    File.join(Rails.root, 'log', 'executions_' + Rails.env)
  end

  def self.remove_statuses
    statuses.keys - [:running]
  end

  def self.plan_store
    DopCommon::PlanStore.new(DopCommon.config.plan_store_dir)
  end

  # This should probably be moved somewhere to dop_common
  def self.list_step_sets(plan_name)
    plan_store.get_plan(plan_name).step_sets.map{|step_set| step_set.name}
  end

  def run
    Log.set_loggers(log)
    status_running!
    update(started_at: Time.now)
    log.info('Execution started')
    case task
    when 'setup'
      dopv_deploy
      dopi_run
    when 'teardown'
      dopv_undeploy
      Dopi.reset(plan, true)
    when 'deploy'
      dopv_deploy
    when 'run'
      dopi_run
    when 'undeploy'
      dopv_undeploy
    else
      raise "Invalid task: #{task}"
    end
    status_done!
    log.info('Execution done')
  rescue Exception => e
    status_failed!
    log.error("Execution failed: #{e.message}: #{e.backtrace.join('\n')}")
  ensure
    update(finished_at: Time.now)
    Log.set_loggers(Delayed::Worker.logger, true)
  end

  def read_log
    File.file?(log_file) ? File.read(log_file) : ''
  end

  def delete_log
    Util.rm_ensure(log_file)
  end

  private

  def log_file
    File.join(self.class.log_dir, self.id.to_s + '.log')
  end

  def log
    FileUtils.mkdir_p(File.dirname(log_file))
    @log ||= Logger.new(log_file)
  end

  # We should probably just support a Hash as an argument
  # in the node_filter method in dop_common
  def options
    if run_options[:run_for_nodes].kind_of?(Hash)
      run_options.merge({
        :run_for_nodes => OpenStruct.new(run_options[:run_for_nodes])
      })
    else
      run_options
    end
  end

  def dopv_deploy
    log.info('Deploying with DOPv')
    Dopv.deploy(self[:plan], options)
  end

  def dopv_undeploy
    log.info('Undeploying with DOPv')
    Dopv.undeploy(self[:plan], options)
  end

  def dopi_run
    log.info('Running DOPi')
    Dopi.run(self[:plan], options) do |plan|
      # May support streaming and pause/stop/kill in the future
    end
  end

end
