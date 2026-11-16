email = 'visual@example.com'
begin
  Authentication::Services::Authenticate.new(email: email, password: 'visual-secret').register!
rescue Authentication::Email::AlreadyClaimed
end
uid = Authentication::HashedEmail.user_id_for_cleartext(email)
Authentication::SomethingUnique.find(uid).update!(color: '8609aa', character: 'S')
pending = Authentication::HashedEmail.from_cleartext('pending@example.com')
EmailVerificationCode.where(id: pending).delete_all
EmailVerificationCode.create!(id: pending, code: 'AB7K', created_at: Time.zone.parse(ENV.fetch('SEED_AT')))
puts "seeded #{uid[0, 8]}"
