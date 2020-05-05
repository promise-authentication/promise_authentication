class Statistics::RecordLoginJob < ApplicationJob
  queue_as :parallel

  def perform(*args)
    raise args.inspect
  end
end
