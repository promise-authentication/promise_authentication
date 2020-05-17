require 'test_helper'

class Trust::CertificateTest < ActiveSupport::TestCase
  setup do
    @described_class = Trust::Certificate
  end

  test 'rotate' do
    assert_equal 0, @described_class.count

    @described_class.rotate!

    assert_equal 1, @described_class.count
  end
end
