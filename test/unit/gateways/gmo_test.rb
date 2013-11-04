require 'test_helper'

class GmoTest < Test::Unit::TestCase
  def setup
    @gateway = GmoGateway.new( :shop_id => 'login', :password => 'password' )

    @credit_card = credit_card
    @amount = 100

    @options = {
      :order_id => '1',
      :billing_address => address,
      :description => 'Store Purchase'
    }
  end

  def test_parse_returns_correct_hash
    test_response = "Key1=Value1|Value2|Value3&Key2=Value4&Key3=Value5&Key4="
    exp = { "Key1" => ["Value1", "Value2", "Value3"],
            "Key2" => ["Value4"],
            "Key3" => ["Value5"],
            "Key4" => nil }

    assert_equal exp, @gateway.send(:parse, test_response)
  end

  def test_action_uri_returns_correct_uri
    assert_equal '/payment/EntryTran.idPass', @gateway.send(:action_uri, 'prepare')
    assert_equal '/payment/ExecTran.idPass', @gateway.send(:action_uri, 'pay')
    # these 3 im not sure what do
    assert_equal '/payment/AlterTran.idPass', @gateway.send(:action_uri, 'alter')
    assert_equal '/payment/ChangeTran.idPass', @gateway.send(:action_uri, 'change')
    assert_equal '/payment/SearchTrade.idPass', @gateway.send(:action_uri, 'search')
  end

  def test_action_returns_correct_test_url
    @gateway.stubs(:test?).returns(true)

    assert_equal 'https://pt01.mul-pay.jp/payment/EntryTran.idPass', @gateway.send(:action, 'prepare')
  end

  def test_action_returns_correct_live_url
    @gateway.stubs(:test?).returns(false)

    assert_equal 'https://p01.mul-pay.jp/payment/EntryTran.idPass', @gateway.send(:action, 'prepare')
  end

  def test_successful_purchase
    @gateway.expects(:ssl_post).returns(successful_purchase_response)

    assert response = @gateway.purchase(@amount, @credit_card, @options)
    assert_instance_of
    assert_success response

    # Replace with authorization number from the successful response
    assert_equal '', response.authorization
    assert response.test?
  end

  def test_unsuccessful_request
    @gateway.expects(:ssl_post).returns(failed_purchase_response)

    assert response = @gateway.purchase(@amount, @credit_card, @options)
    assert_failure response
    assert response.test?
  end

  private

  # Place raw successful response from gateway here
  def successful_purchase_response
  end

  # Place raw failed response from gateway here
  def failed_purchase_response
  end
end
