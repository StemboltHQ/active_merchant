module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    class GmoCommon < Gateway
      self.test_url = 'https://pt01.mul-pay.jp'
      self.live_url = 'https://p01.mul-pay.jp'
      self.homepage_url = 'http://www.gmo-pg.jp/'
      self.money_format = :cents
      self.default_currency = 'JPY'

      # gmo gives us key value pairs in the format of
      # Key=Value|Value|Value&Key2=Value
      def parse( string )
        data = {}

        pairs = string.split('&')
        pairs.each do |kv|
          key, values = kv.split('=')
          data[key.to_sym] = values.nil? ? nil : values.split('|')
        end

        data
      end

      def post_data(params = {})
        post = {}

        post[:ShopID] = @options[:shop_id]
        post[:ShopPass] = @options[:password]

        post.merge(params).map { |k, v| "#{k}=#{CGI.escape(v.to_s)}" }.join("&")
      end

      def search( order_id )
        post = {}
        add_order( post, order_id )

        response = commit 'search', post

        successful_search?( response ) ? response : false
      end

      def commit( action_name, params={} )
        gateway_url = action( action_name )
        data = post_data( params )

        response = parse( ssl_post( gateway_url, data ) )

        if response[:ErrInfo].present?
          errors = gmo_errors(response[:ErrInfo])

          response[:errors] = errors
        end

        return response
      end

      def action( name )
        path = action_uri name
        url = test? ? test_url : live_url

        "#{url}#{path}"
      end

      def post_data(params = {})
        post = {}

        post[:ShopID] = @options[:shop_id]
        post[:ShopPass] = @options[:password]

        post.merge(params).map { |k, v| "#{k}=#{CGI.escape(v.to_s)}" }.join("&")
      end

      def add_money( post, money )
        post[:Amount] = amount(money).to_i
      end

      def add_order( post, order_id )
        post[:OrderID] = format_order_id( order_id )  # grab the rnumber
      end

      def format_order_id( order_id )
        order_id = order_id.split('-').first if order_id.include? '-'
        order_id
      end

      def add_credentials( post, prepare_response )
        post[:AccessID] = prepare_response[:AccessID].first
        post[:AccessPass] = prepare_response[:AccessPass].first
      end

      def successful_prepare? response
        successful_response?(response) &&
        response[:AccessID].present? &&
        response[:AccessPass].present?
      end

      def successful_konbini? response
        successful_response?(response) &&
        response[:OrderID].present? &&
        response[:Convenience].present? &&
        response[:ConfNo].present? &&
        response[:ReceiptNo].present? &&
        response[:PaymentTerm].present? &&
        response[:TranDate].present? &&
        response[:CheckString].present?
      end

      def successful_response? response
        response.is_a? Hash
      end
    end
  end
end

