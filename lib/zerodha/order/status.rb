module Zerodha
  module Order
    class Status < Zerodha::Base
      #
      # In Zerodha the Account nuimber is ignored
      #
      values do
        attribute :token, String
        attribute :account_number, String
        attribute :order_number, String
      end

      def self.result(result)
        result
      end

      def call

        uri = URI.join(Zerodha.api_uri, "orders?api_key=#{Zerodha.api_key}&access_token=#{token}")

        req = Net::HTTP::Get.new(uri, initheader = {
                                   'Content-Type' => 'application/json'
                                 })

        resp = Zerodha.call_api(uri, req)
        result = Zerodha::Order::Status.result(JSON.parse(resp.body))

        if resp.code == '200'
          transactions = result['data']
          orders = {}
          transactions.each do |transaction|
            filled_quantity = transaction.has_key?('filled_quantity') ? transaction['filled_quantity'].to_f : 0.0
            filled_value = transaction.has_key?('filled_quantity') && transaction.has_key?('average_price') ? transaction['filled_quantity'].to_f * transaction['average_price'].to_f : 0.0
            filled_price = filled_quantity > 0 ? filled_value / filled_quantity : 0.0
            order = {
              ticker: transaction['tradingsymbol'].downcase,
              order_action: Zerodha.order_status_actions[transaction['transaction_type']],
              filled_quantity: filled_quantity.to_f,
              filled_price: filled_price.to_f,
              filled_total: filled_value.to_f,
              order_number: transaction['order_id'],
              quantity: transaction['quantity'].to_f,
              expiration: Zerodha.order_status_expirations[transaction['validity']],
              status: Zerodha.order_statuses[transaction['status']]
            }
            orders[transaction['order_id']] = order
          end

          payload_orders = orders.keys.map do |key|
            orders[key] if (order_number && key == order_number) || ! order_number
          end.compact

          if payload_orders.count > 0
            payload = {
              type: 'success',
              orders: payload_orders,
              token: token
            }

            self.response = Zerodha::Base::Response.new(
              raw: result,
              payload: payload,
              messages: Array('success'),
              status: 200
            )
          else
            raise Trading::Errors::OrderException.new(
              type: :error,
              code: '403',
              description: 'No Orders found',
              messages: ['No Orders found']
            )
          end

          # pp response.to_h
          Zerodha.logger.info response.to_h
          self

        else
          raise Trading::Errors::OrderException.new(
            type: :error,
            code: resp.code,
            description: result['message'],
            messages: result['message']
          )
        end

      end

      def parse_time(time_string)
        Time.parse(time_string).utc.to_i
      rescue
        Time.now.utc.to_i
      end
    end
  end
end
