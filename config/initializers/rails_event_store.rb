require 'aggregate_root'
require 'ruby_event_store/mappers/transformation/serialization'

module YAMLProxy
  def self.dump(value) = YAML.dump(value)

  def self.load(serialized) = YAML.unsafe_load(serialized)
end

RubyEventStore::Mappers::Transformation::Serialization.class_eval do
  def initialize(serializer: YAMLProxy)
    @serializer = YAMLProxy
  end
end

Rails.configuration.to_prepare do
  Rails.configuration.event_store = event_store = RailsEventStore::Client.new

  event_store.subscribe_to_all_events( Authentication::EventListener )

  AggregateRoot.configure do |config|
    config.default_event_store = event_store
  end
end

