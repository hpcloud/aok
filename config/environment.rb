# This is mainly for rake tasks. When running under 
# supervisord this is set in the ../aok startup script
ENV['RACK_ENV'] ||= 'production'