# Sends an SMS via MessageBird. Used to deliver verification and recovery
# codes to phone identifiers.
#
# Delivery method:
#   :messagebird - really send (default in production)
#   :logger      - log the message (incl. the code) so you can read it from
#                  the server output while developing (default in development)
#   :test        - collect into .deliveries instead of sending (default in
#                  test, mirroring ActionMailer test delivery)
class Authentication::Services::SmsSender
  include ActiveModel::Model

  class DeliveryError < StandardError; end

  attr_accessor :to, :body

  class << self
    attr_writer :delivery_method

    def delivery_method
      @delivery_method ||= case Rails.env
                           when 'production' then :messagebird
                           when 'test' then :test
                           else :logger
                           end
    end

    def deliveries
      @deliveries ||= []
    end

    def client
      @client ||= MessageBird::Client.new(ENV['MESSAGEBIRD_API_KEY'])
    end

    # Mostly useful in tests.
    def reset!
      @deliveries = []
      @client = nil
    end
  end

  def call
    case self.class.delivery_method
    when :test
      self.class.deliveries << { to: to, body: body }
    when :logger
      self.class.deliveries << { to: to, body: body }
      Rails.logger.info("[SmsSender] To #{to}: #{body}")
    when :messagebird
      deliver!
    else
      raise DeliveryError, "Unknown SMS delivery method: #{self.class.delivery_method.inspect}"
    end
  end

  private

  def deliver!
    retries = 0
    max_retries = 3

    begin
      self.class.client.message_create(originator, [to], body)
    rescue Net::OpenTimeout, Net::ReadTimeout => e
      retries += 1
      raise e unless retries <= max_retries

      sleep(retries * 2)
      retry
    end
  end

  def originator
    ENV.fetch('MESSAGEBIRD_ORIGINATOR', 'Promise')
  end
end
