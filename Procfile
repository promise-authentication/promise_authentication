release: rails db:migrate
web: bundle exec puma -C config/puma.rb
workers: WORKERS=Workers::Default,Workers::Parallel bin/rake sneakers:run
