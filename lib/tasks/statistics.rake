namespace :statistics do
  desc "Delete visit statistics older than Statistics::RETENTION (see /privacy)"
  task sweep: [:environment] do
    Statistics.sweep_old!
  end
end
