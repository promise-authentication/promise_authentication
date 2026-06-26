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

  test 'flag emoji is derived from the ISO code' do
    assert_equal '🇩🇰', country_flag_emoji('DK')
    assert_equal '🇬🇧', country_flag_emoji('GB')
  end
end
