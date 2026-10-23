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

  private

  def sign_in_as_root
    Authentication::Services::Authenticate.new(email: 'root@example.com', password: 'secret').register!
    ENV['PROMISE_ROOT_USER_IDS'] = Authentication::HashedEmail.user_id_for_cleartext('root@example.com')
    post authenticate_url, params: { email: 'root@example.com', password: 'secret' }
  end

  teardown { ENV.delete('PROMISE_ROOT_USER_IDS') }
end
