class Authentication::RelyingParty
  include ActiveModel::Model

  attr_accessor :id

  def self.find(id)
    return nil if id.blank?

    new(id: id)
  end
end
