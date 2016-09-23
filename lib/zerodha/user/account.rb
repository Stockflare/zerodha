module Zerodha
  module User
    #
    # Unlike Tradeit getting these result is a multi step process
    # First you need to get the Users account in order to convert
    # an account_number into an account ID.  Then you need to get
    # the Account Blotter and sum up all the Equity positions.
    #
    class Account < Zerodha::Base
      values do
        attribute :token, String
        attribute :account_number, String
      end

      def call
        details = Zerodha::User.get_account(token, account_number)
        account = details[:account]
        user_id = details[:user_id]

        uri = URI.join(Zerodha.api_uri, "v1/users/#{user_id}/accountSummary/#{account['accountID']}")
        req = Net::HTTP::Get.new(uri, initheader = {
                                   'Content-Type' => 'application/json',
                                   'x-mysolomeo-session-key' => token
                                 })

        resp = Zerodha.call_api(uri, req)

        result = JSON.parse(resp.body)
        if resp.code == '200'
          payload = {
            type: 'success',
            cash: result['cash']['cashBalance'].to_f,
            power: result['cash']['cashAvailableForTrade'].to_f,
            day_return: 0.0,
            day_return_percent: 0.0,
            total_return: 0.0,
            total_return_percent: 0.0,
            value: result['equity']['equityValue'].to_f,
            token: token
          }

          # Deal with positions to create summary values
          total_cost_basis = 0.0
          total_return = 0.0
          total_day_return = 0.0
          total_market_value = 0.0
          total_close_market_value = 0.0
          result['equity']['equityPositions'].each do |position|
            total_cost_basis += position['costBasis'].to_f
            total_return += position['unrealizedPL'].to_f
            total_day_return += position['unrealizedDayPL'].to_f
            total_market_value += (position['mktPrice'].to_f * position['openQty'].to_f)
            total_close_market_value += (position['priorClose'].to_f * position['openQty'].to_f)
          end

          payload[:day_return] = total_day_return.round(4)
          payload[:total_return] = total_return.round(4)
          if total_cost_basis > 0
            payload[:total_return_percent] = (total_return / total_cost_basis).round(4)
          end
          if (total_market_value - total_day_return) != 0
            payload[:day_return_percent] = (total_day_return / (total_market_value - total_day_return)).round(4)
          end
          self.response = Zerodha::Base::Response.new(
            raw: result,
            payload: payload,
            messages: Array('success'),
            status: 200
          )
        else
          raise Trading::Errors::LoginException.new(
            type: :error,
            code: resp.code,
            description: result['message'],
            messages: result['message']
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
