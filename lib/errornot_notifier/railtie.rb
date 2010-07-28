require 'errornot_notifier'
require 'rails'

module ErrornotNotifier
  class Railtie < Rails::Railtie
    rake_tasks do
      require "errornot_notifier/rails3_tasks"
    end

    config.app_middleware.insert_after "::ActionDispatch::ShowExceptions", "ErrornotNotifier::Rack"

    config.after_initialize do
      ErrornotNotifier.configure(true) do |config|
        config.logger           = Rails.logger
        # config.environment_name = Rails.env
        # config.project_root     = Rails.root
        config.framework        = "Rails: #{::Rails::VERSION::STRING}"
      end
    end


  end
end
