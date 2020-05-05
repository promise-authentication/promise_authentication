release: rails db:migrate
web: bin/rails server
workers: WORKERS=Workers::Default,Workers::Parallel bin/rake sneakers:run
