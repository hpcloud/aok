module Ehok
  module Config

    def self.get_database_config
      AppConfig[:database_environment][ENV['RACK_ENV'].to_sym]
    end

    def self.initialize_database
      ActiveRecord::Base.establish_connection(get_database_config)
    end

  end
end
