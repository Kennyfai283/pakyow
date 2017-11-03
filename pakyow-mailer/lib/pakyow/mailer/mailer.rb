module Pakyow
  class Mailer
    attr_accessor :view, :message, :processed

    def self.from_store(view_path, view_store, context = nil)
      view = view_store.view(view_path)
      new(view: Pakyow::Presenter::ViewContext.new(view, context))
    end

    def initialize(view: nil, content: nil, config: nil)
      @view = view
      @content = content
      @config = config

      @message = Mail.new

      if @config
        @message.from          = config.default_sender
        @message.content_type  = config.default_content_type
        @message.delivery_method(config.delivery_method, config.delivery_options)
      end

      @processed = false
    end

    def deliver_to(recipient, subject = nil)
      html = content :html
      text = content :text

      if html.nil?
        @message.body = text
      else
        encoding = @config.encoding
        @message.html_part do
          content_type 'text/html; charset=' + encoding
          body html
        end

        @message.text_part do
          body text
        end
      end

      @message.subject = subject if subject

      Array(recipient).each {|r| deliver(r)}
    end

    def content(type = :html)
      return process.fetch(type, nil)
    end

    protected

    def process
      unless @processed
        @processed_content = {}

        if @view
          @premailer = Premailer.new(view.to_html, with_html_string: true, input_encoding: @config.encoding)

          @premailer.warnings.each do |w|
            Pakyow.logger.warn "#{w[:message]} (#{w[:level]}) may not render properly in #{w[:clients]}"
          end

          @processed_content[:text] = @content || @premailer.to_plain_text
          @processed_content[:html] = @premailer.to_inline_css
        else
          @processed_content[:text] = @content
        end

        @processed = true
      end

      return @processed_content
    end

    def deliver(recipient)
      @message.to = recipient
      @message.deliver
    end
  end
end
