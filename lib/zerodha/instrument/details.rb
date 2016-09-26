module Zerodha
  module Instrument
    class Details < Zerodha::Base
      #
      # Zerodha does not support Instrument::Details therefore this
      # function will always fail
      #
      values do
        attribute :token, String
        attribute :ticker, String
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
