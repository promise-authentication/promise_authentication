module PhoneHelper
  # A few dial-callable ISO codes phonelib ships that the countries gem has no
  # entry for. Names are the same across our locales, so a flat map is enough.
  COUNTRY_NAME_OVERRIDES = {
    'AC' => 'Ascension Island',
    'TA' => 'Tristan da Cunha',
    'XK' => 'Kosovo'
  }.freeze

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
  # then alphabetical by name. The dial codes come from phonelib so the list
  # stays in sync with parsing; the localized name comes from the countries gem.
  # The name leads the label so the native <select> typeahead can match it
  # (typing "d" jumps to Denmark) — a leading flag emoji would defeat that.
  def phone_country_options
    # Keyed by locale: the names are localized, so a single cache would otherwise
    # leak one locale's list into another (only observable when the locale changes
    # within a single view, e.g. in tests — a request keeps one locale throughout).
    (@phone_country_options ||= {})[I18n.locale] ||= begin
      options = Phonelib.phone_data.filter_map do |iso, data|
        next unless iso.match?(/\A[A-Z]{2}\z/)

        dial = data[:country_code]
        next if dial.blank?

        name = country_name(iso)
        ["#{name} #{country_flag_emoji(iso)} +#{dial}", "+#{dial}", name]
      end

      default = options.find { |(_, dial, _)| dial == phone_default_dial_code }
      sorted = (options - [default]).sort_by { |(_, _, name)| name.downcase }
      [default, *sorted].compact.map { |(label, dial, _)| [label, dial] }
    end
  end

  # Localized ISO-3166 country name (e.g. "Danmark" in :da, "Denmark" in :en),
  # falling back to the English short name and then the raw ISO code.
  def country_name(iso)
    country = ISO3166::Country.new(iso)
    return COUNTRY_NAME_OVERRIDES.fetch(iso, iso) unless country

    country.translation(I18n.locale.to_s) || country.iso_short_name || iso
  end

  # Turns an ISO-3166 alpha-2 code into its flag emoji (regional indicators).
  def country_flag_emoji(iso)
    iso.upcase.each_char.map { |c| (0x1F1E6 + (c.ord - 'A'.ord)).chr(Encoding::UTF_8) }.join
  end
end
