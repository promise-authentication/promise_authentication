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
end
