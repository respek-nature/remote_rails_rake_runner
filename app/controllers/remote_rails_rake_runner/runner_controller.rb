require_dependency 'remote_rails_rake_runner/application_controller'

module RemoteRailsRakeRunner
  class RunnerController < ApplicationController
    before_action :load_rake
    skip_before_action :verify_authenticity_token rescue ArgumentError

    def index
      tasks = Rake.application.tasks.map do |t|
        {
            name: t.to_s,
            args: t.arg_names,
            description: t.comment,
        }
      end

      render json: tasks
    end

    def run
      success = true
      rake_tasks = Rake.application.tasks
      task = rake_tasks.find { |t| t.name == params[:task] }

      begin
        output = capture_stdout do
          override_env(environment_params) { task.invoke(*(params[:args] || '').split(',')) }
        end
      rescue => e
        success = false
        output = e.inspect
        callstack = e.backtrace.to_json
      ensure
        # rake_tasks.each { |task| task.reenable }
      end

      response = {success: success, output: output}
      response[:callstack] = callstack if callstack
      render json: response
    end

    def reneable_environment
      rake_tasks = Rake.application.tasks
      rake_tasks.each { |task| task.reenable }
    end

    def reneable_rake
      rake_tasks = Rake.application.tasks
      task = rake_tasks.find { |t| t.name == params[:task] }
      return head :not_found unless task

      task.reenable
    end

    private

    def environment_params
      params[:environment].permit! if params[:environment].respond_to?(:permit!)
      params[:environment]
    end

    def capture_stdout
      previous, $stdout = $stdout, StringIO.new
      yield
      $stdout.string
    ensure
      $stdout = previous
    end

    def override_env(variables)
      unless variables.blank?
        begin
          previous = ENV.to_h
          ENV.update(variables)
          yield
        ensure
          ENV.replace(previous)
        end
      else
        yield
      end
    end

    def load_rake
      return if defined? Rake.application

      require 'rake'
      load Rails.application.config.try(:remote_rake_runner_rakefile_path) || Rails.root.join('Rakefile').to_s
    end
  end
end
