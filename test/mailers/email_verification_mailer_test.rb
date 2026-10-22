require 'test_helper'

class EmailVerificationMailerTest < ActionMailer::TestCase
  test 'the delivered subject and from-line are built by the shared helpers' do
    mail = EmailVerificationMailer.with(
      email: 'x@example.com',
      code: 'abcd',
      relying_party_name: 'Oase'
    ).verify_email

    assert_equal EmailVerificationMailer.subject_for(code: 'abcd', relying_party_name: 'Oase'),
                 mail.subject
    assert_equal "#{EmailVerificationMailer.from_name_for(relying_party_name: 'Oase')} <#{EmailVerificationMailer::FROM_ADDRESS}>",
                 mail[:from].to_s
  end

  test 'without a relying party the mail comes from plain Promise' do
    mail = EmailVerificationMailer.with(email: 'x@example.com', code: 'abcd').verify_email

    assert_equal EmailVerificationMailer.subject_for(code: 'abcd'), mail.subject
    assert_equal "Promise <#{EmailVerificationMailer::FROM_ADDRESS}>", mail[:from].to_s
  end

  test 'the mail carries the delivery token and bounces go to the bounce address' do
    old = ENV['PROMISE_BOUNCE_ADDRESS']
    ENV['PROMISE_BOUNCE_ADDRESS'] = 'bounces@promiseauthentication.org'

    mail = EmailVerificationMailer.with(email: 'x@example.com', code: 'abcd', delivery_token: 'tok_1234567890abcdefgh').verify_email

    assert_equal 'tok_1234567890abcdefgh', mail[Bounces::TOKEN_HEADER].to_s
    assert_equal 'bounces@promiseauthentication.org', mail.return_path
    assert_equal 'bounces@promiseauthentication.org', mail.smtp_envelope_from
    assert_equal "Promise <#{EmailVerificationMailer::FROM_ADDRESS}>", mail[:from].to_s
  ensure
    old ? ENV['PROMISE_BOUNCE_ADDRESS'] = old : ENV.delete('PROMISE_BOUNCE_ADDRESS')
  end

  test 'without a bounce address the envelope sender stays the From address' do
    ENV.delete('PROMISE_BOUNCE_ADDRESS')
    mail = EmailVerificationMailer.with(email: 'x@example.com', code: 'abcd').verify_email

    assert_nil mail.return_path
    assert_nil mail[Bounces::TOKEN_HEADER]
    assert_equal EmailVerificationMailer::FROM_ADDRESS, mail.smtp_envelope_from
  end
end
