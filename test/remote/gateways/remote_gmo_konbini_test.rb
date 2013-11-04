#encoding: utf-8

require 'test_helper'

class RemoteGmoKonbiniTest < Test::Unit::TestCase
  def setup
    @gateway = GmoKonbiniGateway.new(fixtures(:gmo))

    @amount = 100

    @options = {
      :order_id => "#{DateTime.current.to_time.to_i}#{Random.rand(99999)}-asda",
      :billing_address => address,
      :description => 'Store Purchase'
    }

    @konbini = OpenStruct.new(
      convenience_id: '00003'
    )
  end

  def test_successful_authorize
    assert response = @gateway.authorize(@amount, @konbini, @options)
    assert_success response
    assert_equal 'Success', response.message
  end

  def test_bad_amount
    assert response = @gateway.authorize(-1, @konbini, @options)
    assert_failure response
    assert_equal '利用金額に数字以外の文字が含まれています。', response.message
  end

  def test_bad_login
    gateway = GmoKonbiniGateway.new( shop_id: '', password: '', shop_name: '', shop_hours: '', shop_phone: '' )
    assert response = gateway.authorize(@amount, @konbini, @options)
    assert_failure response
    # no shop id, no password, no shop & password found.
    assert_equal 'ショップIDが指定されていません。, ショップパスワードが指定されていません。, and 指定されたIDとパスワードのショップが存在しません。', response.message
  end
end
