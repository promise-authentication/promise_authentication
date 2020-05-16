namespace :trust do
  desc "Rollover certificates"
  task roll_certificates: [:environment] do
    Trust::Certificate.rollover!
  end
end
