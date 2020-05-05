class Workers::Base
  include Sneakers::Worker

  def self.queue_opts
    {
      durable: true,
      ack: true,
      arguments: {
        :'x-dead-letter-exchange' => "#{queue_name}-retry"
      }
    }
  end

  def work(msg)
    job_data = ActiveSupport::JSON.decode(msg)
    ActiveJob::Base.execute job_data
    ack!
  end
end
