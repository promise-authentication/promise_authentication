class Statistics::RecordLoginJob < ApplicationJob
  queue_as :parallel

  def perform(*args)
  end
end
