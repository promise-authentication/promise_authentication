class Root::FunnelController < RootController
  STEPS = %w[started human_verified mail_sent confirmed_code confirmed_magic_link password_created].freeze
  SIGN_IN_STEPS = %w[started password_failed recovery_requested signed_in handed_off].freeze
  WEEKS = 12

  def show
    events = events_named('registration_step')
    sign_in_events = events_named('sign_in_step')

    @windows = {
      'Today' => Time.current.beginning_of_day,
      '7 days' => 7.days.ago,
      '30 days' => 30.days.ago,
      'All time' => nil
    }

    @counts = window_counts(events)
    @sign_in_counts = window_counts(sign_in_events)

    @resends = @windows.transform_values do |since|
      rows = since ? events.select { |time, _| time >= since } : events
      rows.count { |_, properties| properties['resend'].to_s == 'true' }
    end

    # Bounce notices shown (see Bounces), by reason category.
    @bounces = @windows.transform_values do |since|
      rows = since ? events.select { |time, _| time >= since } : events
      rows.select { |_, properties| properties['step'] == 'mail_bounced' }
          .map { |_, properties| properties['reason'].presence || 'other' }
          .tally
    end

    # Verification mails that never left (see RegistrationsController#
    # report_mail_failure), by error and SMTP reply code.
    @mail_failures = @windows.transform_values do |since|
      rows = since ? events.select { |time, _| time >= since } : events
      rows.select { |_, properties| properties['step'] == 'mail_failed' }
          .map { |_, properties| properties.values_at('error', 'smtp_code').compact.join(' ') }
          .tally
    end

    # How tokens were handed off: straight from the password form or via
    # the confirm page's button, to an app (custom scheme) or the web.
    @handoffs = @windows.transform_values do |since|
      rows = since ? sign_in_events.select { |time, _| time >= since } : sign_in_events
      rows.select { |_, properties| properties['step'] == 'handed_off' }
          .map { |_, properties| "#{properties['via'] || '?'} → #{properties['handoff'] || '?'}" }
          .tally
    end

    @weekly = weekly_counts(events)
    @sign_in_weekly = weekly_counts(sign_in_events)
  end

  private

  # Tallied in Ruby, not SQL: ahoy_events.properties is a plain text
  # column in production, so Postgres has no ->> operator for it — and
  # the all-time column needs the full set anyway.
  def events_named(name)
    Ahoy::Event.where(name: name).pluck(:time, :properties).map do |time, properties|
      properties = JSON.parse(properties) if properties.is_a?(String)
      [time, properties || {}]
    end
  end

  def window_counts(events)
    @windows.transform_values do |since|
      rows = since ? events.select { |time, _| time >= since } : events
      rows.map { |_, properties| properties['step'] }.tally
    end
  end

  # Step tallies per calendar week (Monday start), newest first, for the
  # last WEEKS weeks — the current, partial week included. Lets a change
  # in completion be read against deploy dates.
  def weekly_counts(events)
    this_week = Date.current.beginning_of_week
    weeks = (0...WEEKS).map { |i| this_week - i.weeks }
    by_week = events.group_by { |time, _| time.to_date.beginning_of_week }

    weeks.index_with do |week|
      (by_week[week] || []).map { |_, properties| properties['step'] }.tally
    end
  end
end
