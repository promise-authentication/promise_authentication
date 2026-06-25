require 'test_helper'

class Authentication::Services::SmsSenderTest < ActiveSupport::TestCase
  setup do
    @described_class = Authentication::Services::SmsSender
    @described_class.reset!
  end

  teardown do
    @described_class.delivery_method = nil
    @described_class.reset!
  end

  test 'defaults to test delivery outside production' do
    assert_equal :test, @described_class.delivery_method
  end

  test 'test delivery collects messages instead of sending' do
    @described_class.new(to: '+4520123456', body: 'hello').call

    assert_equal 1, @described_class.deliveries.size
    assert_equal({ to: '+4520123456', body: 'hello' }, @described_class.deliveries.last)
  end

  test 'unknown delivery method raises' do
    @described_class.delivery_method = :carrier_pigeon
    assert_raises Authentication::Services::SmsSender::DeliveryError do
      @described_class.new(to: '+4520123456', body: 'hi').call
    end
  end
end
