module OpenID
  class Consumer
    class CheckIDRequest
      def get_message(realm, return_to=nil, immediate=false)
        if !return_to.nil?
          return_to = Util.append_args(return_to, @return_to_args)
        elsif immediate
          raise ArgumentError, ('"return_to" is mandatory when using '\
                                '"checkid_immediate"')
        elsif @message.is_openid1
          raise ArgumentError, ('"return_to" is mandatory for OpenID 1 '\
                                'requests')
        elsif @return_to_args.empty?
          raise ArgumentError, ('extra "return_to" arguments were specified, '\
                                'but no return_to was specified')
        end


        message = @message.copy

        mode = immediate ? 'checkid_immediate' : 'checkid_setup'
        message.set_arg(OPENID_NS, 'mode', mode)

        realm_key = message.is_openid1 ? 'trust_root' : 'realm'
        message.set_arg(OPENID_NS, realm_key, realm)

        if !return_to.nil?
          message.set_arg(OPENID_NS, 'return_to', return_to)
        end

        if not @anonymous
          if @endpoint.is_op_identifier
            # This will never happen when we're in OpenID 1
            # compatibility mode, as long as is_op_identifier()
            # returns false whenever preferred_namespace returns
            # OPENID1_NS.
            claimed_id = request_identity = IDENTIFIER_SELECT
          else
            request_identity = @endpoint.get_local_id
            claimed_id = @endpoint.claimed_id
          end

          # This is true for both OpenID 1 and 2
          message.set_arg(OPENID_NS, 'identity', request_identity)

          if message.is_openid2
            message.set_arg(OPENID2_NS, 'claimed_id', claimed_id)
          end
        end

        if @assoc && (message.is_openid1 || !['checkid_setup', 'checkid_immediate'].include?(mode))
          message.set_arg(OPENID_NS, 'assoc_handle', @assoc.handle)
          assoc_log_msg = "with assocication #{@assoc.handle}"
        else
          assoc_log_msg = 'using stateless mode.'
        end

        Util.log("Generated #{mode} request to #{@endpoint.server_url} "\
                 "#{assoc_log_msg}")
        return message
      end
    end
  end
end
