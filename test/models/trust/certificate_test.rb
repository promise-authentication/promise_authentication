require 'test_helper'

class Trust::CertificateTest < ActiveSupport::TestCase
  setup do
    @described_class = Trust::Certificate
  end

  test 'rotate' do
    assert_equal 0, @described_class.count

    @described_class.rotate!

    assert_equal 1, @described_class.count

    key = @described_class.current
    assert key[:private_key].match('PRIVATE')
    assert_not key[:private_key].match('PUBLIC')
    assert key[:public_key].match('PUBLIC')
    assert_not key[:public_key].match('PRIVATE')
  end
end
