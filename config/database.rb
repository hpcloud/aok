require 'kato/logging'
require 'kato/doozer'
Kato::Logging.log_to_stderr = true

module Ehok
  module Config

    def self.get_database_config
      # Get the DB connection params from Doozer

      rails_environment = Kato::Doozer.get_component_config_value(
        "cloud_controller", "rails_environment")
      db_config, db_config_rev = Kato::Doozer.get_component_config(
        "cloud_controller", { :path => File.join("database_environment", rails_environment), :symbolize_keys => true})

      db_config.merge!(:database => "ehok_#{rails_environment}")
      return db_config
    end

    def self.initialize_database
      ActiveRecord::Base.establish_connection(get_database_config)
    end

  end
end
