class Root::FunnelController < RootController
  STEPS = %w[started human_verified mail_sent confirmed_code confirmed_magic_link password_created].freeze

  def show
    events = Ahoy::Event.where(name: 'registration_step')

    @windows = {
      'Today' => Time.current.beginning_of_day,
      '7 days' => 7.days.ago,
      '30 days' => 30.days.ago,
      'All time' => nil
    }

    @counts = @windows.transform_values do |since|
      scope = since ? events.where(time: since..) : events
      scope.group(Arel.sql("properties ->> 'step'")).count
    end

    @resends = @windows.transform_values do |since|
      scope = since ? events.where(time: since..) : events
      scope.where("properties ->> 'resend' = 'true'").count
    end
  end
end
