class Authentication::PersonalData
  include ActiveModel::Model

  attr_accessor :emails, :ids

  def email
    emails&.first
  end

  def add_email(email)
    @emails ||= []
    @emails << email
  end

  def id_for(relying_party)
    @ids ||= {}
    @ids[relying_party]
  end

  def add_id(id, relying_party)
    @ids ||= {}
    @ids[relying_party] = id
  end

  def to_json
    {
      emails: emails,
      ids: ids
    }.to_json
  end
end
