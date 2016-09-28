module Zerodha
  module Instrument
    class Details < Zerodha::Base
      values do
        attribute :token, String
        attribute :ticker, String
      end

      def call

        # Get the Exchnage for the required instrument
        begin
          exchange = Zerodha::Instrument::List.new().call.response.payload.list[ticker.upcase].exchange
        rescue NoMethodError
          raise Trading::Errors::OrderException.new(
            type: :error,
            code: 400,
            description: "Exchange code for ticker #{ticker} could not be found",
            messages: "Exchange code for ticker #{ticker} could not be found"
          )
        end
        if exchange
          # Lookup the Stock in order to get ID and prices
          uri = URI.join(Zerodha.api_uri, "instruments/#{exchange.upcase}/#{ticker.upcase}?api_key=#{Zerodha.api_key}&access_token=#{token}")
          req = Net::HTTP::Get.new(uri, initheader = {
                                     'Content-Type' => 'application/json'
                                   })

          resp = Zerodha.call_api(uri, req)
          result = JSON.parse(resp.body)
          if resp.code == '200'

            if result.empty?
              raise Trading::Errors::OrderException.new(
                type: :error,
                code: 403,
                description: 'Broker does not trade this instrument',
                messages: 'Broker does not trade this instrument'
              )
            else
              instrument = result['data']
              payload = {
                type: 'success',
                broker_id: ticker.downcase,
                ticker: ticker.downcase,
                last_price: instrument['last_price'].to_f,
                bid_price: instrument['depth']['buy'][0]['price'].to_f,
                ask_price: instrument['depth']['sell'][0]['price'].to_f,
                order_size_max: 99999.0,
                order_size_min: 1.0,
                order_size_step: 1.0,
                allow_fractional_shares: false,
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
        else
          raise Trading::Errors::OrderException.new(
            type: :error,
            code: 400,
            description: "Exchange code for ticker #{ticker} could not be found",
            messages: "Exchange code for ticker #{ticker} could not be found"
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
