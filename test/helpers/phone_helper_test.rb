require 'test_helper'

class PhoneHelperTest < ActionView::TestCase
  test 'default dial code follows the default region' do
    assert_equal '+45', phone_default_dial_code
  end

  test 'country options put the default region first' do
    label, dial = phone_country_options.first
    assert_equal '+45', dial
    assert_includes label, '🇩🇰'
    assert_includes label, '+45'
  end

  test 'every option is a [label, +dial] pair and covers many countries' do
    options = phone_country_options
    assert_operator options.size, :>, 200
    assert(options.all? { |(label, dial)| label.present? && dial.start_with?('+') })

    dials = options.map(&:last)
    assert_includes dials, '+44' # GB
    assert_includes dials, '+1'  # US/CA
  end

  test 'the localized country name leads each label so native typeahead can match it' do
    I18n.with_locale(:en) do
      label, dial = phone_country_options.find { |(l, _)| l.start_with?('United Kingdom') }
      assert_equal '+44', dial
      assert_equal 'United Kingdom 🇬🇧 +44', label
    end

    I18n.with_locale(:da) do
      label, dial = phone_country_options.find { |(_, d)| d == '+49' }
      assert_equal 'Tyskland 🇩🇪 +49', label
      assert_equal '+49', dial
    end
  end

  test 'non-default options are sorted alphabetically by name' do
    names = phone_country_options.drop(1).map { |(label, _)| label }
    assert_equal names, names.sort_by(&:downcase)
  end

  test 'country_name falls back to an override for codes the countries gem lacks' do
    assert_equal 'Kosovo', country_name('XK')
    assert_includes phone_country_options.map(&:first).join("\n"), 'Kosovo'
  end

  test 'flag emoji is derived from the ISO code' do
    assert_equal '🇩🇰', country_flag_emoji('DK')
    assert_equal '🇬🇧', country_flag_emoji('GB')
  end
end
