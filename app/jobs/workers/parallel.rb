class Workers::Parallel < Workers::Base
  def self.queue_name
    'parallel'
  end
end
