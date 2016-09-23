module Zerodha
  module Instrument
    class Details < Zerodha::Base
      values do
        attribute :token, String
        attribute :ticker, String
      end

      def call

        # Lookup the Stock in order to get ID and prices
        uri = URI.join(Zerodha.api_uri, "v1/instruments?symbol=#{ticker}")
        req = Net::HTTP::Get.new(uri, initheader = {
                                   'Content-Type' => 'application/json',
                                   'x-mysolomeo-session-key' => token,
                                   'Accept' => 'application/json'
                                 })

        resp = Zerodha.call_api(uri, req)
        if resp.code == '200'
          result = JSON.parse(resp.body)
          if result.empty?
            raise Trading::Errors::OrderException.new(
              type: :error,
              code: 403,
              description: 'Broker does not trade this instrument',
              messages: 'Broker does not trade this instrument'
            )
          else
            instrument = result[0]

            payload = {
              type: 'success',
              broker_id: instrument['instrumentID'].downcase,
              ticker: instrument['symbol'].downcase,
              last_price: instrument['lastTrade'].to_f,
              bid_price: instrument['rateBid'].to_f,
              ask_price: instrument['rateAsk'].to_f,
              order_size_max: instrument['orderSizeMax'].to_f,
              order_size_min: instrument['orderSizeMin'].to_f,
              order_size_step: instrument['orderSizeStep'].to_f,
              allow_fractional_shares: (instrument['orderSizeStep'].to_f < 1.0 && instrument['orderSizeStep'].to_f > 0.0 ? true : false),
              timestamp: Time.now.utc.to_i,
              warnings: [],
              must_acknowledge: [],
              token: token
            }
            self.response = Zerodha::Base::Response.new(
              raw: result,
              payload: payload,
              messages: Array('success'),
              status: 200
            )

          end

        else
          raise Trading::Errors::OrderException.new(
            type: :error,
            code: resp.code,
            description: result['message'],
            messages: result['message']
          )
        end
        self
      end

      def parse_time(time_string)
        Time.parse(time_string).utc.to_i
      rescue
        Time.now.utc.to_i
      end
    end
  end
end
