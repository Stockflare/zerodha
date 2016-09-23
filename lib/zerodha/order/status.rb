module Zerodha
  module Order
    class Status < Zerodha::Base
      values do
        attribute :token, String
        attribute :account_number, String
        attribute :order_number, String
      end

      def call
        blotter = Zerodha::User::Account.new(token: token, account_number: account_number).call.response
        transactions = blotter.raw['transactions']
        orders = {}
        transactions.each do |transaction|
          filled_quantity = transaction.has_key?('cumQty') ? transaction['cumQty'].to_f : 0.0
          filled_value = transaction.has_key?('cumQty') && transaction.has_key?('executedPrice') ? transaction['cumQty'].to_f * transaction['executedPrice'].to_f : 0.0
          filled_price = filled_quantity > 0 ? filled_value / filled_quantity : 0.0
          order = {
            ticker: transaction['symbol'].downcase,
            order_action: Zerodha.order_status_actions[transaction['side']],
            filled_quantity: filled_quantity.to_f,
            filled_price: filled_price.to_f,
            filled_total: filled_value.to_f,
            order_number: transaction['orderNo'],
            quantity: transaction['orderQty'].to_f,
            expiration: :day,
            status: Zerodha.order_statuses[transaction['orderStatus']]
          }
          orders[transaction['orderNo']] = order
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
            raw: blotter.raw,
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
      end

      def parse_time(time_string)
        Time.parse(time_string).utc.to_i
      rescue
        Time.now.utc.to_i
      end
    end
  end
end
