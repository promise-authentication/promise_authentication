# In development we don't send real e-mail (delivery_method is :test). This
# observer logs every delivered message — including verification and recovery
# codes — to the server output so you can read them while testing locally.
if Rails.env.development?
  module DevelopmentMailLogger
    def self.delivered_email(message)
      body = message.text_part&.body&.decoded ||
             message.html_part&.body&.decoded ||
             message.body&.decoded

      Rails.logger.info(
        "[Mailer] To #{Array(message.to).join(', ')} | #{message.subject}\n#{body}"
      )
    end
  end

  ActionMailer::Base.register_observer(DevelopmentMailLogger)
end
