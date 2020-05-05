require 'sneakers/handlers/maxretry'
require 'sneakers'

Sneakers.configure(
  handler: Sneakers::Handlers::Maxretry,
  amqp: ENV['CLOUDAMQP_URL'] || 'amqp://guest:guest@localhost:5672',
  prefetch: 1,
  threads: 1,
  workers: 1,
  exchange_options: { durable: true },
)

Sneakers.logger.level = Logger::INFO
