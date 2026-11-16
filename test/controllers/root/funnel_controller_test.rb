require 'test_helper'

class Root::FunnelControllerTest < ActionDispatch::IntegrationTest
  test 'requires a signed-in root user' do
    get '/root/funnel'
    assert_redirected_to %r{/login}
  end

  test 'shows bounce notices by reason next to the funnel' do
    visit = Ahoy::Visit.create!(started_at: Time.current)
    Ahoy::Event.create!(visit: visit, name: 'registration_step', time: Time.current, properties: { step: 'started' })
    Ahoy::Event.create!(visit: visit, name: 'registration_step', time: Time.current, properties: { step: 'mail_sent' })
    Ahoy::Event.create!(visit: visit, name: 'registration_step', time: Time.current, properties: { step: 'mail_sent' })
    Ahoy::Event.create!(visit: visit, name: 'registration_step', time: Time.current,
                        properties: { step: 'mail_bounced', reason: 'mailbox_not_found' })
    Ahoy::Event.create!(visit: visit, name: 'registration_step', time: 40.days.ago,
                        properties: { step: 'mail_bounced', reason: 'rejected' })

    sign_in_as_root
    get '/root/funnel'
    assert_response :success

    row = css_select('tr').find { |tr| tr.text.include?('bounced (notice shown)') }
    assert row
    cells = row.css('td').map { |td| td.text.squish }
    assert_equal 'bounced (notice shown)', cells[0].delete('↳').strip
    assert_equal '1 (50% of sent) mailbox_not_found 1', cells[1] # today
    assert_equal '2 (100% of sent) mailbox_not_found 1 rejected 1', cells[4] # all time
  end

  test 'shows mail send failures next to the funnel' do
    visit = Ahoy::Visit.create!(started_at: Time.current)
    2.times do
      Ahoy::Event.create!(visit: visit, name: 'registration_step', time: Time.current,
                          properties: { step: 'mail_failed', error: 'SMTPServerBusy', smtp_code: '421', recipient: 'microsoft' })
    end
    Ahoy::Event.create!(visit: visit, name: 'registration_step', time: Time.current,
                        properties: { step: 'mail_failed', error: 'ReadTimeout', recipient: 'other' })

    sign_in_as_root
    get '/root/funnel'

    cells = css_select('#mail_failed td').map { |td| td.text.squish }
    assert_equal '3 SMTPServerBusy 421 microsoft 2 ReadTimeout other 1', cells[1] # today
  end

  test 'shows completion per week' do
    visit = Ahoy::Visit.create!(started_at: Time.current)
    this_week = Time.current.beginning_of_week + 1.hour
    last_week = this_week - 1.week
    { 'started' => 2, 'mail_sent' => 2, 'confirmed_code' => 1, 'password_created' => 1 }.each do |step, n|
      n.times { Ahoy::Event.create!(visit: visit, name: 'registration_step', time: this_week, properties: { step: step }) }
    end
    { 'started' => 4, 'confirmed_magic_link' => 3, 'password_created' => 3 }.each do |step, n|
      n.times { Ahoy::Event.create!(visit: visit, name: 'registration_step', time: last_week, properties: { step: step }) }
    end

    sign_in_as_root
    get '/root/funnel'
    assert_response :success

    rows = css_select('#weekly tbody tr').map { |tr| tr.css('td').map { |td| td.text.squish } }
    assert_equal Root::FunnelController::WEEKS, rows.size
    assert_equal ["#{this_week.to_date.strftime('%Y-%m-%d')} *", '2', '2', '0', '1', '1', '50%'], rows[0]
    assert_equal [last_week.to_date.strftime('%Y-%m-%d'), '4', '0', '0', '3', '3', '75%'], rows[1]
    assert_equal '–', rows[2].last
  end

  test 'shows sign-in completion by window and by week' do
    visit = Ahoy::Visit.create!(started_at: Time.current)
    now = Time.current.beginning_of_week + 1.hour
    { 'started' => 4, 'password_failed' => 3, 'signed_in' => 3 }.each do |step, n|
      n.times { Ahoy::Event.create!(visit: visit, name: 'sign_in_step', time: now, properties: { step: step }) }
    end
    [%w[password web]] * 3 + [%w[confirm app]] * 2 => routes
    routes.each do |via, handoff|
      Ahoy::Event.create!(visit: visit, name: 'sign_in_step', time: now,
                          properties: { step: 'handed_off', via: via, handoff: handoff })
    end

    sign_in_as_root
    get '/root/funnel'
    assert_response :success

    routes_row = css_select('#sign_in tbody tr').find { |tr| tr.text.include?('handed_off by route') }
    assert_equal 'password → web 3 confirm → app 2', routes_row.css('td').last.text.squish
    signed_in = css_select('#sign_in tbody tr').find { |tr| tr.text.include?('signed_in') }
    assert_equal '3 (75%)', signed_in.css('td').last.text.squish # all time
    week = css_select('#sign_in_weekly tbody tr').first.css('td').map { |td| td.text.squish }
    assert_equal ["#{now.to_date.strftime('%Y-%m-%d')} *", '4', '3', '0', '3', '5', '75%'], week
  end

  private

  def sign_in_as_root
    Authentication::Services::Authenticate.new(email: 'root@example.com', password: 'secret').register!
    ENV['PROMISE_ROOT_USER_IDS'] = Authentication::HashedEmail.user_id_for_cleartext('root@example.com')
    post authenticate_url, params: { email: 'root@example.com', password: 'secret' }
  end

  teardown { ENV.delete('PROMISE_ROOT_USER_IDS') }
end
