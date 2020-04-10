require 'aggregate_root'

Rails.configuration.to_prepare do
  Rails.configuration.event_store = event_store = RailsEventStore::Client.new

  event_store.subscribe_to_all_events( Authentication::EventListener )

  AggregateRoot.configure do |config|
    config.default_event_store = event_store
  end
end

