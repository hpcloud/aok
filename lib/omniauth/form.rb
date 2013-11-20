require 'omniauth'

module OmniAuth
  class Form
    DEFAULT_CSS = '' unless defined? DEFAULT_CSS

    attr_accessor :options

    def initialize(options = {})
      options[:title] ||= "Authentication Info Required"
      options[:header_info] ||= ""
      self.options = options

      @html = ""
      @with_custom_button = false
      header(options[:title],options[:header_info])
    end

    def self.build(options = {},&block)
      form = OmniAuth::Form.new(options)
      if block.arity > 0
        yield form
      else
        form.instance_eval(&block)
      end
      form
    end

    def label_field(text, target)
      @html << "\n<div class='form-group'><label class='col-lg-2 control-label' for='#{target}'>#{text}:</label>"
      self
    end

    def input_field(type, name, label=nil)
      label ||= name
      @html << "\n<div class='col-lg-10'><input type='#{type}' class='form-control' id='#{name}' name='#{name}' placeholder='#{label}'/></div></div>"
      self
    end

    def text_field(label, name)
      label_field(label, name)
      input_field('text', name, label)
      self
    end

    def password_field(label, name)
      label_field(label, name)
      input_field('password', name, label)
      self
    end

    def button(text)
      @with_custom_button = true
      @html << "\n" << '<input class="signin-button btn btn-primary btn-lg pull-right" type="submit" value="' << text << '">'
    end

    def html(html)
      @html << html
    end

    def fieldset(legend, options = {}, &block)
      @html << "\n<fieldset#{" style='#{options[:style]}'" if options[:style]}#{" id='#{options[:id]}'" if options[:id]}>\n  <legend>#{legend}</legend>\n"
      self.instance_eval(&block)
      @html << "\n</fieldset>"
      self
    end

    def header(title,header_info)
      @html << <<-HTML
      <!DOCTYPE html>
      <html>
      <head>
        <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
        <title>#{title}</title>
        <link href="/console/css/console.css" rel="stylesheet" />
        <script type="text/javascript">
          $CC_URL = "//#{cc_url}"
        </script>
        <script src="/console/js/lib/jquery/jquery-1.10.1.min.js"></script>
        <script src="/aok/aok.js"></script>
        #{header_info}
      </head>
      <body class="login">
        <div id="header-container">
          <nav class="navbar navbar-default navbar-inverse navbar-fixed-top" role="navigation">
            <img class="navbar-brand" src="/console/img/stackato_logo_header.png" alt="Stackato">
          </nav>
        </div>
        <div class="page_wrapper">
          <div class="container">
            <div class="content">
              <div id="invalid_credentials" class="alert alert-danger hide">Sorry.  Your attempt to sign in failed.  Please try again.</div>
              <div class="well">
                <h2>#{title}</h2>
                <form id="login_form" class="form form-horizontal" method='post' #{"action='#{options[:url]}' " if options[:url]}noValidate='noValidate'>
      HTML
      self
    end

    def footer
      return self if @footer
      @html << "\n" << '<input class="signin-button btn btn-primary btn-lg pull-right" type="submit" value="Sign in">' unless @with_custom_button
      @html << <<-HTML
                </form>
                <div class='clearfix'></div>
              </div>
            </div><!-- .content -->
          </div>
        </div>
      </body>
      </html>
      HTML
      @footer = true
      self
    end

    def to_html
      footer
      @html
    end

    def to_response
      footer
      Rack::Response.new(@html).finish
    end

    def cc_url
      CCConfig[:external_uri]
    end

  end
end
