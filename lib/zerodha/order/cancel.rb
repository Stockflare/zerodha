module Zerodha
  module Order
    class Cancel < Zerodha::Base
      #
      # Zerodha does not support Order::Cancel therefore this
      # function will always fail
      #
      values do
        attribute :token, String
        attribute :account_number, String
        attribute :order_number, String
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
