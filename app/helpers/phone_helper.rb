module PhoneHelper
  def phone_default_region
    (ENV['DEFAULT_PHONE_REGION'].presence || 'DK').upcase
  end

  # The dial code (e.g. "+45") for the default region — used as the
  # pre-selected value in the country selector.
  def phone_default_dial_code
    code = Phonelib.phone_data.dig(phone_default_region, :country_code)
    "+#{code}"
  end

  # [[label, "+dial"], ...] for every callable country, default region first
  # then alphabetical. Built from phonelib so it stays in sync with parsing.
  def phone_country_options
    @phone_country_options ||= begin
      options = Phonelib.phone_data.filter_map do |iso, data|
        next unless iso.match?(/\A[A-Z]{2}\z/)

        dial = data[:country_code]
        next if dial.blank?

        ["#{country_flag_emoji(iso)} +#{dial}", "+#{dial}"]
      end

      default = options.find { |(_, dial)| dial == phone_default_dial_code }
      [default, *(options - [default]).sort_by { |(label, _)| label }].compact
    end
  end

  # Turns an ISO-3166 alpha-2 code into its flag emoji (regional indicators).
  def country_flag_emoji(iso)
    iso.upcase.each_char.map { |c| (0x1F1E6 + (c.ord - 'A'.ord)).chr(Encoding::UTF_8) }.join
  end
end
