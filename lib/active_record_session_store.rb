require 'rack/session/abstract/id'

module Rack
  module Session
    class ActiveRecord < Abstract::ID
      def initialize(app, options={})
        super(app, options.merge!(:cookie_only => false))
      end

      # Should return [session_id, session]
      # If nil is provided as the session id, generation of a new valid id
      # should occur within.
      def get_session(env, sid)
        session = nil
        if sid && session = ::Session.find_by_sid(sid)
          data = decode(session.data) rescue {}
        else
          data = {}
        end
        session ||= ::Session.new(:sid => generate_sid)
        session.data = encode(data)
        session.save! if session.changed?
        [session.sid, data]
      end

      def set_session(env, sid, data, options)
        session = ::Session.find_or_initialize_by_sid(sid)
        session.data = encode(data)
        if session.save
          return session.sid
        end
        return false
      end

      # Should return a new session id or nil if options[:drop]
      def destroy_session(env, sid, options)
        ::Session.delete_all(:conditions => {:sid => sid})
        generate_sid unless options[:drop]
      end

      def generate_sid
        SecureRandom.urlsafe_base64(@sidbits/6)
      end

      def encode(data)
        [Marshal.dump(data)].pack('m').chomp
      end

      def decode(str)
        Marshal.load(str.unpack('m').first)
      end
    end
  end
end