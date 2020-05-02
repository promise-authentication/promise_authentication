class Authentication::SomethingUnique < ApplicationRecord
  def self.generate
    new(
      color: ColorGenerator.new(saturation: 0.9, lightness: 0.35).create_hex,
      character: SecureRandom.alphanumeric.first.upcase
    )
  end

  def to_h
    {
      color: color,
      character: character
    }
  end
end
