module Zerodha
  module User
    #
    # This is a multi step process, you need to get the user's account summary
    # and then get all the holid and positions data
    #
    class Account < Zerodha::Base
      values do
        attribute :token, String
        attribute :account_number, String
      end

      def self.positions_result(positions_result)
        positions_result
      end

      def self.holdings_result(holdings_result)
        holdings_result
      end

      def call
        details = Zerodha::User::Login.new(user_id: 'na', user_token: token).call.response

        holdings_uri = URI.join(Zerodha.api_uri, "portfolio/holdings?api_key=#{Zerodha.api_key}&access_token=#{token}")
        holdings_req = Net::HTTP::Get.new(holdings_uri, initheader = {
                                   'Content-Type' => 'application/json'
                                 })

        holdings_resp = Zerodha.call_api(holdings_uri, holdings_req)
        holdings_result = Zerodha::User::Account.holdings_result(JSON.parse(holdings_resp.body))

        if holdings_resp.code == '200'

          positions_uri = URI.join(Zerodha.api_uri, "portfolio/positions?api_key=#{Zerodha.api_key}&access_token=#{token}")
          positions_req = Net::HTTP::Get.new(positions_uri, initheader = {
                                     'Content-Type' => 'application/json'
                                   })

          positions_resp = Zerodha.call_api(positions_uri, positions_req)
          positions_result = Zerodha::User::Account.positions_result(JSON.parse(positions_resp.body))

          if positions_resp.code == '200'
            # Now need to combine all the positions and holdings
            account_positions = {}
            holdings_result['data'].each do |holding|
              parse_instrument(holding, account_positions)
            end
            positions_result['data']['net'].each do |position|
              parse_instrument(position, account_positions)
            end

            payload = {
              type: 'success',
              cash: details['raw']['data']['available']['cash'].to_f,
              power: details['raw']['data']['net'].to_f,
              day_return: 0.0,
              day_return_percent: 0.0,
              total_return: 0.0,
              total_return_percent: 0.0,
              value: 0.0,
              token: token
            }

            # Deal with positions to create summary values
            total_cost_basis = 0.0
            total_return = 0.0
            total_day_return = 0.0
            total_market_value = 0.0
            total_close_market_value = 0.0
            account_positions.keys.each do |k|
              position = account_positions[k]
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
            payload[:value] = total_market_value

            self.response = Zerodha::Base::Response.new(
              raw: account_positions,
              payload: payload,
              messages: Array('success'),
              status: 200
            )

          else
            raise Trading::Errors::LoginException.new(
              type: :error,
              code: positions_resp.code,
              description: positions_result['message'],
              messages: positions_result['message']
            )
          end
        else
          raise Trading::Errors::LoginException.new(
            type: :error,
            code: holdings_resp.code,
            description: holdings_result['message'],
            messages: holdings_result['message']
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

      def parse_instrument(instrument, account_positions)
        ticker = instrument['tradingsymbol']

        # Get the Stockflare ticker by isin
        if instrument.has_key?('isin')
          search_uri = URI.join(Zerodha.search_url, 'filter')
          search_req = Net::HTTP::Put.new(search_uri, initheader = {
                                     'Content-Type' => 'application/json'
                                   })
          search_req.body = {
            conditions: {
              isin: instrument['isin'].downcase,
              country_code: 'ind'
            },
            select: ['sic', 'ticker']
          }.to_json
          search_resp = Zerodha.call_api(search_uri, search_req)
          if search_resp.code == '200'
            search_result = JSON.parse(search_resp.body)
            if search_result.count > 0
              ticker = search_result[0]['ticker']
            end
          end
        end

        if !account_positions.has_key?(ticker)
          account_positions[ticker] = {
            'costBasis' => 0.0,
            'unrealizedPL' => 0.0,
            'unrealizedDayPL' => 0.0,
            'mktPrice' => 0.0,
            'openQty' => 0.0,
            'priorClose' => 0.0
          }
        end
        position = account_positions[ticker]
        position['costBasis'] = position['costBasis'] + (instrument['average_price'].to_f * instrument['quantity'].to_f)
        position['unrealizedPL'] = position['unrealizedPL'] + instrument['pnl'].to_f
        position['mktPrice'] = instrument['last_price'].to_f
        position['openQty'] = position['openQty'] + instrument['quantity'].to_f
        position['priorClose'] = instrument['close_price'].to_f
        position['unrealizedDayPL'] = (position['openQty'] * position['priorClose']) - (position['openQty'] * position['mktPrice'])

        account_positions
      end
    end
  end
end
