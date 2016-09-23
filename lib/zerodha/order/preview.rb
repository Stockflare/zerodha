module Zerodha
  module Order
    class Preview < Zerodha::Base
      values do
        attribute :token, String
        attribute :account_number, String
        attribute :order_action, Symbol
        attribute :quantity, Float
        attribute :ticker, String
        attribute :price_type, Symbol
        attribute :expiration, Symbol
        attribute :limit_price, Float
        attribute :stop_price, Float
        attribute :amount, Float
      end

      def self.buying_power(power)
        return power
      end
      def self.shares(shares)
        return shares
      end

      def call
        # Reject any order that has an amount and is not Market
        if amount && amount != 0.0 && price_type != :market
          raise Trading::Errors::OrderException.new(
            type: :error,
            code: 500,
            description: 'Amount only suppoorted for market orders',
            messages: 'Amount only suppoorted for market orders'
          )
        end

        details = Zerodha::User.get_account(token, account_number)
        account = details[:account]
        blotter = Zerodha::User::Account.new(token: token, account_number: account_number).call.response.payload
        user_id = details[:user_id]
        buying_power = Zerodha::Order::Preview.buying_power(blotter['power'].to_f)
        shares = 0
        positions = Zerodha::Positions::Get.new(
          token: token,
          account_number: account_number
        ).call.response.payload
        position = positions.positions.select do |p|
          p[:ticker] == ticker
        end
        shares = Zerodha::Order::Preview.shares(position && !position.empty? ? position[0][:quantity] : 0.0)

        # Get the User details so we can get the Commission amount
        uri = URI.join(Zerodha.api_uri, "v1/users/#{user_id}")
        req = Net::HTTP::Get.new(uri, initheader = {
                                   'Content-Type' => 'application/json',
                                   'x-mysolomeo-session-key' => token,
                                   'Accept' => 'application/json'
                                 })
        resp = Zerodha.call_api(uri, req)
        result = JSON.parse(resp.body)

        if resp.code == '200'
          commission_rate = result['commissionRate'].to_f

          # Hack for Drivewealth fractional shares
          if quantity < 1.0
            commission_rate = 0.99
          end

          # Lookup the Stock in order to get ID and prices
          uri = URI.join(Zerodha.api_uri, "v1/instruments?symbol=#{ticker}")
          req = Net::HTTP::Get.new(uri, initheader = {
                                     'Content-Type' => 'application/json',
                                     'x-mysolomeo-session-key' => token,
                                     'Accept' => 'application/json'
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
              instruments = result.select{ |i| i['symbol'].downcase === ticker.downcase }
              if instruments.empty?
                raise Trading::Errors::OrderException.new(
                  type: :error,
                  code: 403,
                  description: 'Broker does not trade this instrument',
                  messages: 'Broker does not trade this instrument'
                )
              else
                instrument = instruments[0]
                if order_action == :buy  || order_action == :buy_to_cover
                  if amount && amount > 0
                    estimated_value = amount
                  else
                    estimated_value = quantity * instrument['rateAsk'].to_f
                  end
                else
                    if amount && amount > 0
                      estimated_value = amount
                    else
                      estimated_value = quantity * instrument['rateBid'].to_f
                    end
                end
                if (order_action == :sell || order_action == :sell_short) && shares < quantity
                  raise Trading::Errors::OrderException.new(
                    type: :error,
                    code: 403,
                    description: 'You do not own enough shares',
                    messages: 'You do not own enough shares'
                  )
                else
                  if (order_action == :sell || order_action == :sell_short) || ((order_action == :buy || order_action == :buy_to_cover) && (estimated_value + commission_rate) <= buying_power)
                    payload = {
                      type: 'review',
                      ticker: instrument['symbol'].downcase,
                      order_action: order_action,
                      quantity: quantity,
                      expiration: expiration,
                      price_label: '',
                      value_label: '',
                      message: '',
                      last_price: instrument['lastTrade'].to_f,
                      bid_price: instrument['rateBid'].to_f,
                      ask_price: instrument['rateAsk'].to_f,
                      timestamp: Time.now.utc.to_i,
                      buying_power: blotter['power'].to_f,
                      estimated_commission: commission_rate,
                      estimated_value: estimated_value,
                      estimated_total: estimated_value + commission_rate,
                      warnings: [],
                      must_acknowledge: [],
                      amount: amount,
                      token: token
                    }
                    # Prioritise Amount orders over quantity orders
                    if amount && amount > 0
                      payload[:amount] = amount
                      payload[:quantity] = 0.0
                    else
                      payload[:amount] = 0.0
                      payload[:quantity] = quantity
                    end

                    raw = attributes.reject { |k, _v| k == :response }.merge(instrument: instrument,
                                                                             account: account,
                                                                             user_id: user_id,
                                                                             commission: commission_rate,
                                                                             amount: amount)
                    self.response = Zerodha::Base::Response.new(
                      raw: raw,
                      payload: payload,
                      messages: Array('success'),
                      status: 200
                    )

                    # Cache the Order details for the Order Execute Call
                    Zerodha.cache.set("#{Zerodha::CACHE_PREFIX}_#{token}", response.to_h.to_json, 60)
                  else
                    raise Trading::Errors::OrderException.new(
                      type: :error,
                      code: 403,
                      description: 'Not enough Buying Power',
                      messages: 'Not enough Buying Power'
                    )
                  end

                end
              end


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
