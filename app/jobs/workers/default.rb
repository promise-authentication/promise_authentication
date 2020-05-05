class Workers::Default < Workers::Base
  def self.queue_name
    'default'
  end
end
