require File.dirname(__FILE__) + '/gmo/gmo_errors'
require File.dirname(__FILE__) + '/gmo/gmo_common'

module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    class GmoGateway < GmoCommon
      include GmoErrors

      self.supported_countries = ['JA']
      self.supported_cardtypes = [:visa, :master, :jcb, :american_express, :diners_club]
      self.homepage_url = 'http://www.gmo-pg.jp/'
      self.display_name = 'GMO Credit Card'

      def initialize(options = {})
        requires!(options, :shop_id, :password)
        super
      end

      # If you get here by google and are interested in using GMO
      # in active_merchant then have a look at the following ref.
      # This branch/code is very specific to our codebase. The ref
      # below is the last commit where this gateway could be used
      # without any external code. glhf. - DylanJ
      #
      # ref: b99abb5e38d8995888904e5592ce1dddd2b43b35
      def purchase(money, credit_card, options = {})
        requires!(options, :order_id)
        requires!(options, :AccessID)
        requires!(options, :AccessPass)
        order_id = format_order_id( options[:order_id] )

        post = {}
        post[:Method] = 1
        post[:JobCd] = 'CAPTURE'

        post[:AccessID] = options[:AccessID]
        post[:AccessPass] = options[:AccessPass]

        add_credit_card( post, credit_card )
        add_order( post, order_id )

        response = commit 'pay', post

        if successful_payment? response
          return Response.new true, 'Success', response, { test: test?, authorization: order_id }
        end

        Response.new false, response[:errors], response, { test: test?, authorization: order_id }
      end

      def capture(*args)
        Response.new true, 'Success', {}, { test: test? }
      end

      def void(order_id, options={})
        if search_response = search(order_id)
          post = {}
          post[:JobCd] = 'VOID'

          add_order( post, order_id )
          add_credentials( post, search_response )

          response = commit 'alter', post

          return Response.new true, 'Success', response, { test: test? }
        end

        Response.new false, 'Order ID not found', {}, { test: test? }
      end

      def credit(money, authorization, options = {})
        deprecated CREDIT_DEPRECATION_MESSAGE
        refund(money, authorization, options)
      end

      def refund(money, order_id, options = {})
        if search_response = search(order_id)

          # only support full refunds right now.
          if search_response[:Amount].first.to_i != amount(money).to_i
            return Response.new false, 'No Partial Refunds', search_response, { test: test? }
          end

          post = {}
          post[:JobCd] = 'RETURN'
          add_credentials(post, search_response)

          response = commit 'alter', post

          # appropriate response -> success
          if successful_prepare? response
            return Response.new true, 'Success', response, { test: test? }
          end

          # test this some how.
          return Response.new false, response[:errors], response, { test: test? }
        end

        Response.new false, 'Order ID not found', {}, { test: test? }
      end

      def prepare( money, order_id )
        post = {}
        post[:JobCd] = 'CAPTURE'

        add_money( post, money )
        add_order( post, order_id )

        commit 'prepare', post
      end

      private

      def action_uri( name )
        case name
        when 'prepare'
          '/payment/EntryTran.idPass'
        when 'pay'
          '/payment/ExecTran.idPass'
        when 'alter'
          '/payment/AlterTran.idPass'
        when 'change'
          '/payment/ChangeTran.idPass'
        when 'search'
          '/payment/SearchTrade.idPass'
        else
          raise "GMO Action #{name} is unsupported"
        end
      end

      def successful_search? response
        successful_response?(response) &&
        successful_prepare?(response) &&
        successful_payment?(response) &&
        response[:JobCd].present? &&
        response[:Amount].present? &&
        response[:Tax].present?
      end

      def successful_payment? response
        successful_response?(response) &&
        response[:Approve].present? &&
        response[:TranID].present?
      end

      def add_credit_card( post, credit_card )
        post[:CardNo] = credit_card.number
        post[:Expire] = expiry(credit_card)
        post[:SecurityCode] = credit_card.verification_value
      end

      def expiry credit_card
        year  = format(credit_card.year, :two_digits)
        month = format(credit_card.month, :two_digits)
        "#{year}#{month}"
      end
    end
  end
end

