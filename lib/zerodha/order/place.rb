module Zerodha
  module Order
    class Place < Zerodha::Base
      #
      # Zerodha does not support Order::Place therefore this
      # function will always fail
      #
      values do
        attribute :token, String
        attribute :price, Float
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
