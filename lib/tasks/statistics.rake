namespace :statistics do
  desc "Delete usage statistics older than Statistics::RETENTION (see /privacy)"
  task sweep: [:environment] do
    Statistics.sweep_old!
  end
end
