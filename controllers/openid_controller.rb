%W{
  pathname

  openid
  openid/consumer/discovery
  openid/extensions/sreg
  openid/extensions/pape
  openid/store/filesystem
}.each{|l| require l}

class OpenidController < ApplicationController
  include OpenID::Server

  get_and_post '/?' do
    begin
      oidreq = server.decode_request(params)
    rescue ProtocolError => e
      # invalid openid request, so just display a page with an error message
      logger.debug "Invalid openid request: #{e.to_s}"
      halt 500, e.to_s
    end

    # no openid.mode was given
    unless oidreq
      logger.debug "No oidreq"
      halt "This is an OpenID server endpoint!"
    end
    oidresp = nil

    if oidreq.kind_of?(CheckIDRequest)

      identity = oidreq.identity

      if oidreq.id_select
        if oidreq.immediate
          oidresp = oidreq.answer(false)
        elsif session[:username].nil?
          # The user hasn't logged in.
          logger.debug "not logged in, Showing decision page"
          return show_decision_page(oidreq)
        else
          # Else, set the identity to the one the user is using.
          identity = url_for_user
        end
      end

      if oidresp
        nil
      elsif self.is_authorized(identity, oidreq.trust_root)
        oidresp = oidreq.answer(true, nil, identity)

        # add the sreg response if requested
        add_sreg(oidreq, oidresp)
        # ditto pape
        add_pape(oidreq, oidresp)

      elsif oidreq.immediate
        server_url = url_for :action => 'index'
        oidresp = oidreq.answer(false, server_url)

      else
        return show_decision_page(oidreq)
      end

    else
      oidresp = server.handle_request(oidreq)
    end

    self.render_response(oidresp)
  end

  def server
    if @server.nil?
      server_url = url('/')
      dir = Pathname.new('.').join('openid-store')
      store = OpenID::Store::Filesystem.new(dir)
      @server = Server.new(store, server_url)
    end
    return @server
  end

  def show_decision_page(oidreq, message="Do you trust this site with your identity?")
    session[:last_oidreq] = oidreq
    @oidreq = oidreq

    erb :decide, :layout => :server
  end

  get '/idp_xrds' do
    types = [
             OpenID::OPENID_IDP_2_0_TYPE,
            ]

    render_xrds(types)
  end

  post '/decision' do
    oidreq = session[:last_oidreq]
    session[:last_oidreq] = nil

    if params[:yes].nil?
      return redirect oidreq.cancel_url
    else
      id_to_send = params[:id_to_send]

      identity = oidreq.identity
      if oidreq.id_select
        if id_to_send and id_to_send != ""
          session[:username] = id_to_send
          session[:approvals] = []
          identity = url_for_user
        else
          msg = "You must enter a username to in order to send " +
            "an identifier to the Relying Party."
          return show_decision_page(oidreq, msg)
        end
      end

      if session[:approvals]
        session[:approvals] << oidreq.trust_root
      else
        session[:approvals] = [oidreq.trust_root]
      end
      oidresp = oidreq.answer(true, nil, identity)
      add_sreg(oidreq, oidresp)
      add_pape(oidreq, oidresp)
      return self.render_response(oidresp)
    end
  end

  protected


  def approved(trust_root)
    return false if session[:approvals].nil?
    return session[:approvals].member?(trust_root)
  end

  def is_authorized(identity_url, trust_root)
    return (session[:username] and (identity_url == url_for_user) and self.approved(trust_root))
  end

  def add_sreg(oidreq, oidresp)
    # check for Simple Registration arguments and respond
    sregreq = OpenID::SReg::Request.from_openid_request(oidreq)

    return if sregreq.nil?
    # In a real application, this data would be user-specific,
    # and the user should be asked for permission to release
    # it.
    sreg_data = {
      'nickname' => session[:username],
      'fullname' => 'Mayor McCheese',
      'email' => 'mayor@example.com'
    }

    sregresp = OpenID::SReg::Response.extract_response(sregreq, sreg_data)
    oidresp.add_extension(sregresp)
  end

  def add_pape(oidreq, oidresp)
    papereq = OpenID::PAPE::Request.from_openid_request(oidreq)
    return if papereq.nil?
    paperesp = OpenID::PAPE::Response.new
    paperesp.nist_auth_level = 0 # we don't even do auth at all!
    oidresp.add_extension(paperesp)
  end

  def render_response(oidresp)
    if oidresp.needs_signing
      signed_response = server.signatory.sign(oidresp)
    end
    web_response = server.encode_response(oidresp)

    case web_response.code
    when HTTP_OK then web_response.body
    when HTTP_REDIRECT then redirect(web_response.headers['location'])
    else [400, web_response.body]
    end
  end

  def url_for_user
    url("/users/#{session[:username]}", true, false)
  end
end