module Statistics
  # Usage statistics are kept this long, as promised in the privacy
  # policy (/privacy) — keep the two in sync.
  RETENTION = 6.months

  def self.table_name_prefix
    'statistics_'
  end

  def self.sweep_old!
    cutoff = RETENTION.ago

    Ahoy::Event.where('time < ?', cutoff).delete_all
    Ahoy::Visit.where('started_at < ?', cutoff).delete_all
    Statistics::SignInEvent.where('created_at < ?', cutoff).delete_all
  end
end
