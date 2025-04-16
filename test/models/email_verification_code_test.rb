require 'test_helper'

class EmailVerificationCodeTest < ActiveSupport::TestCase
  setup do
    @described_class = EmailVerificationCode
  end

  test 'human readable code' do
    klass = @described_class::HumanReadableCode
    100.times do
      generated = klass.generate(2..6)
      assert_equal generated.class, String
      assert generated.length >= 2 && generated.length <= 6,
             "Length should be between 2 and 6 but #{generated} is #{generated.length}"
    end
  end
end
