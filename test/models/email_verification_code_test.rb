require 'test_helper'

class EmailVerificationCodeTest < ActiveSupport::TestCase
  setup do
    @described_class = EmailVerificationCode
  end

  test 'human readable code' do
    klass = @described_class::HumanReadableCode
    assert klass.generate(2..6)
  end
end
