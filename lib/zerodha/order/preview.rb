module Zerodha
  module Order
    class Preview < Zerodha::Base
      #
      # Zerodha does not support Order::Preview therefore this
      # function will always fail
      #
      values do
        attribute :token, String
        attribute :account_number, String
        attribute :order_action, Symbol
        attribute :quantity, Float
        attribute :ticker, String
        attribute :price_type, Symbol
        attribute :expiration, Symbol
        attribute :limit_price, Float
        attribute :stop_price, Float
        attribute :amount, Float
      end

      def call

        raise Trading::Errors::OrderException.new(
          type: :error,
          code: 500,
          description: 'Not Supported',
          messages: ['Not Supported']
        )

      end

    end
  end
end
