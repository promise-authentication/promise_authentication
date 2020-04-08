class Authentication::PersonalData
  include ActiveModel::Model

  attr_accessor :emails

  def add_email(email)
    @emails ||= []
    @emails << email
  end

  def to_json
    {
      emails: emails
    }.to_json
  end
end
