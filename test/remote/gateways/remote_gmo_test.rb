#encoding: utf-8

require 'test_helper'

class RemoteGmoTest < Test::Unit::TestCase
  def setup
    @gateway = GmoGateway.new(fixtures(:gmo))

    @amount = 100
    @credit_card = credit_card('4000100011112224')
    @declined_card = credit_card('4000300011112220')
    @clearly_bad_card = credit_card('123123213123')

    @options = {
      :order_id => "torder-#{DateTime.current.to_time.to_i}-#{Random.rand(99999)}",
      :billing_address => address,
      :description => 'Store Purchase'
    }
  end

  def test_amount_put_in_is_amount_returned
    assert response = @gateway.purchase(@amount, @credit_card, @options)
    response = @gateway.send(:search, @options[:order_id])
    assert_equal @amount.to_s, response[:Amount].first
  end

  def test_void_existing_order_works
    assert response = @gateway.purchase(@amount, @credit_card, @options)
    assert response = @gateway.void(@options[:order_id], @options )
    assert_success response
    assert_equal 'Success', response.message
  end

  def test_void_non_existing_order_fails
    assert response = @gateway.void(@options[:order_id], @options )
    assert_failure response
    assert_equal 'Order ID not found', response.message
  end

  def test_find_existing_order
    order_id = "aneworder1366672295"
    assert response = @gateway.search(order_id)
    assert_equal order_id, response[:OrderID].first
  end

  def test_refund_with_valid_order_id
    assert response = @gateway.purchase(@amount, @credit_card, @options)
    assert response = @gateway.refund(@amount, @options[:order_id], @options )
    assert_success response
    assert_equal "Success", response.message
  end

  def test_refund_with_partial_amount_fails
    assert response = @gateway.purchase(@amount, @credit_card, @options)
    assert response = @gateway.refund(@amount - 1, @options[:order_id], @options)
    assert_failure response
    assert_equal "No Partial Refunds", response.message
  end

  def test_refund_with_invalid_order_id
    assert response = @gateway.refund(@amount, @options[:order_id], @options )
    assert_failure response
    assert_equal 'Order ID not found', response.message
  end

  def test_unsuccessful_search
    assert_equal false, @gateway.search(@options[:order_id])
  end

  def test_successful_search
    @gateway.purchase(@amount, @credit_card, @options)

    assert response = @gateway.search(@options[:order_id])
    assert !response.nil?
  end

  def test_successful_purchase
    assert response = @gateway.purchase(@amount, @credit_card, @options)
    assert_success response
    assert_equal 'Success', response.message
  end

  def test_bad_credit_card
    assert response = @gateway.purchase(@amount, @clearly_bad_card, @options)
    assert_failure response
    # invalid credit card details
    assert_equal 'ご入力いただいた情報が正しいかご確認ください。', response.message
  end

  def test_bad_purchase_amount
    assert response = @gateway.purchase(-1, @credit_card, @options)
    assert_failure response
    # invalid credit card details
    assert_equal '利用金額に数字以外の文字が含まれています。', response.message
  end

  # gmo's test server doesn't seem to check when a credit card expires...
  # def test_bad_credit_card_year
  #   @credit_card.year = 0
  #   @credit_card.month = 0
  #   assert response = @gateway.purchase(@amount, @credit_card, @options)
  #   assert_failure response
  #   # invalid credit card details
  #   assert_equal 'ご入力いただいた情報が正しいかご確認ください。', response.message
  # end

  def test_bad_login
    gateway = GmoGateway.new( shop_id: '', password: '' )
    assert response = gateway.purchase(@amount, @credit_card, @options)
    assert_failure response
    # no shop id, no password, no shop & password found.
    assert_equal 'ショップIDが指定されていません。, ショップパスワードが指定されていません。, and 指定されたIDとパスワードのショップが存在しません。', response.message
  end
end
