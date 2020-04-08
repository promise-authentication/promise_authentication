class Command
  include ActiveModel::Model

  validates :aggregate_class, :aggregate_id, presence: true

  def execute!
    validate!

    stream_name = "#{aggregate_class}$#{aggregate_id}"
    repository = AggregateRoot::Repository.new
    repository.with_aggregate(aggregate_class.new(aggregate_id), stream_name) do |aggregate|
      call(aggregate)
      aggregate
    end
  end
end
