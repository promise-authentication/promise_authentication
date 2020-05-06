class Authentication::PersonalData
  include ActiveModel::Model

  attr_accessor :ids

  def ids
    @ids || {}
  end

  def id_for(relying_party)
    @ids ||= {}
    @ids[relying_party]
  end

  def add_id(id, relying_party)
    @ids ||= {}
    @ids[relying_party] = id
  end

  def to_h
    {
      ids: ids
    }
  end

  def to_json
    to_h.to_json
  end
end
