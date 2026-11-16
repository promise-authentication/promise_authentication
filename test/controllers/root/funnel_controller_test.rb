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
    assert_equal ["#{this_week.to_date.strftime('%Y-%m-%d')} *", '2', '2', '1', '1', '50%'], rows[0]
    assert_equal [last_week.to_date.strftime('%Y-%m-%d'), '4', '0', '3', '3', '75%'], rows[1]
    assert_equal '–', rows[2].last
  end

  private

  def sign_in_as_root
    Authentication::Services::Authenticate.new(email: 'root@example.com', password: 'secret').register!
    ENV['PROMISE_ROOT_USER_IDS'] = Authentication::HashedEmail.user_id_for_cleartext('root@example.com')
    post authenticate_url, params: { email: 'root@example.com', password: 'secret' }
  end

  teardown { ENV.delete('PROMISE_ROOT_USER_IDS') }
end
