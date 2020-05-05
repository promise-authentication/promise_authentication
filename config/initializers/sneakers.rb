require 'sneakers/handlers/maxretry'
require 'sneakers'
require 'airbrake/sneakers'

Sneakers.configure(
  handler: Sneakers::Handlers::Maxretry,
  amqp: ENV['CLOUDAMQP_URL'] || 'amqp://guest:guest@localhost:5672',
  exchange_options: { durable: true },
)

Sneakers.logger.level = Logger::INFO
