namespace :trust do
  desc "Rotate certificates"
  task roll_certificates: [:environment] do
    Trust::Certificate.rotate!
  end
end
