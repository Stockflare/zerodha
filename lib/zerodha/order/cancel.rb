module Zerodha
  module Order
    class Cancel < Zerodha::Base
      values do
        attribute :token, String
        attribute :account_number, String
        attribute :order_number, String
      end

      def call
        blotter = Zerodha::User::Account.new(token: token, account_number: account_number).call.response
        orders = blotter.raw['orders'].select { |o| o['orderNo'] == order_number }
        if orders.count > 0
          order = orders[0]

          order_payload = Zerodha::Order::Status.new(token: token, account_number: account_number, order_number: order_number).call.response.payload
          order_payload['orders'][0][:status] = :cancelled

          uri = URI.join(Zerodha.api_uri, "v1/orders/#{order['orderID']}")

          req = Net::HTTP::Delete.new(uri, initheader = {
                                        'Content-Type' => 'application/json',
                                        'x-mysolomeo-session-key' => token
                                      })

          resp = Zerodha.call_api(uri, req)

          result = JSON.parse(resp.body)

          if resp.code == '200'
            payload = {
              type: 'success',
              orders: order_payload['orders'],
              token: token
            }

            self.response = TradeIt::Base::Response.new(
              raw: result,
              payload: payload,
              messages: Array(result['message']),
              status: 200
            )
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
            code: '403',
            description: 'No Orders found',
            messages: ['No Orders found']
          )
        end

        Zerodha.logger.info response.to_h
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
