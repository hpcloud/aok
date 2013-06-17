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
      @html << "\n<label for='#{target}'>#{text}:</label>"
      self
    end

    def input_field(type, name)
      @html << "\n<input type='#{type}' id='#{name}' name='#{name}'/>"
      self
    end

    def text_field(label, name)
      label_field(label, name)
      input_field('text', name)
      self
    end

    def password_field(label, name)
      label_field(label, name)
      input_field('password', name)
      self
    end

    def button(text)
      @with_custom_button = true
      @html << "\n" << '<input class="signin-button" type="submit" value="' << text << '">'
    end

    def html(html)
      @html << html
    end

    def fieldset(legend, options = {}, &block)
      @html << "\n<fieldset#{" style='#{options[:style]}'" if options[:style]}#{" id='#{options[:id]}'" if options[:id]}>\n  <legend>#{legend}</legend>\n"
      self.instance_eval &block
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
        <link href="//#{cc_url}/all-1.css" rel="stylesheet" />
        <link href="//#{cc_url}/theme/style.css" rel="stylesheet" />
        <script src="//#{cc_url}/theme/settings.js"></script>
        <script type="text/javascript">
          $CC_URL = "//#{cc_url}"
        </script>
        <script src="/jquery-1.10.1.min.js"></script>
        <script src="/aok.js"></script>
        #{header_info}
      </head>
      <body class="login">
        <div class="page_wrapper">
          <div class="content">
            <div class="login_logo">
              <div class="stackato_logo"></div>
              <h2>#{title}</h2>
              
            </div>
            <form id="login_form" method='post' #{"action='#{options[:url]}' " if options[:url]}noValidate='noValidate'>
      HTML
      self
    end

    def footer
      return self if @footer
      @html << "\n" << '<input class="signin-button" type="submit" value="Sign in">' unless @with_custom_button
      @html << <<-HTML
            </form>
          </div><!-- .content -->
        </div><!-- .page_wrapper -->
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
