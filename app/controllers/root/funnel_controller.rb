class Root::FunnelController < RootController
  STEPS = %w[started human_verified mail_sent confirmed_code confirmed_magic_link password_created].freeze

  def show
    # Tallied in Ruby, not SQL: ahoy_events.properties is a plain text
    # column in production, so Postgres has no ->> operator for it — and
    # the all-time column needs the full set anyway.
    events = Ahoy::Event.where(name: 'registration_step').pluck(:time, :properties).map do |time, properties|
      properties = JSON.parse(properties) if properties.is_a?(String)
      [time, properties || {}]
    end

    @windows = {
      'Today' => Time.current.beginning_of_day,
      '7 days' => 7.days.ago,
      '30 days' => 30.days.ago,
      'All time' => nil
    }

    @counts = @windows.transform_values do |since|
      rows = since ? events.select { |time, _| time >= since } : events
      rows.map { |_, properties| properties['step'] }.tally
    end

    @resends = @windows.transform_values do |since|
      rows = since ? events.select { |time, _| time >= since } : events
      rows.count { |_, properties| properties['resend'].to_s == 'true' }
    end
  end
end
