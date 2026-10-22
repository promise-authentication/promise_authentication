namespace :bounces do
  desc 'Read the bounce mailbox and flag pending verification codes whose mail bounced'
  task poll: [:environment] do
    result = Bounces::Mailbox.poll!
    puts result ? "#{result[:reports]} reports, #{result[:matched]} matched a pending code" : 'bounce mailbox not configured'
  end
end
