class Authentication::Commands::AddSomethingUnique < Command
  attr_accessor :user_id, :something_unique
  alias_method :aggregate_id, :user_id

  validates :something_unique, presence: true

  def aggregate_class
    Authentication::Human
  end

  def call(human)
    human.add_something_unique(something_unique: something_unique)
  end
end
