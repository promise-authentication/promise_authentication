require 'test_helper'

class Trust::CertificateTest < ActiveSupport::TestCase
  setup do
    @described_class = Trust::Certificate
  end

  test 'rollover' do
    assert_equal 0, @described_class.count

    @described_class.rollover!

    assert_equal 1, @described_class.count
  end
end
