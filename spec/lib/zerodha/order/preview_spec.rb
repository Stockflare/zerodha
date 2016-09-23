require 'spec_helper'

describe Zerodha::Order::Preview do
  let(:username) { 'stockflare.ff' }
  let(:password) { 'passw0rd' }
  let(:broker) { :zerodha }
  let!(:user) do
    Zerodha::User::LinkAndLogin.new(
      username: username,
      password: password,
      broker: broker
    ).call.response.payload
  end
  let(:token) { user.token }
  let(:account_number) { user.accounts[0].account_number }
  let(:order_action) { :buy }
  let(:price_type) { :market }
  let(:order_expiration) { :day }
  let(:quantity) { 10 }
  let(:ticker) { 'aapl' }
  let(:buying_power) { 10000 }
  let(:shares) { 100 }
  let(:base_order) do
    {
      token: token,
      account_number: account_number,
      order_action: order_action,
      quantity: quantity,
      ticker: ticker,
      price_type: price_type,
      expiration: order_expiration
    }
  end
  let(:order_extras) do
    {}
  end

  before do
    allow(Zerodha::Order::Preview).to receive(:buying_power).and_return(buying_power)
    allow(Zerodha::Order::Preview).to receive(:shares).and_return(shares)
  end

  subject do
    Zerodha::Order::Preview.new(
      base_order.merge(order_extras)
    ).call.response
  end

  describe 'Buy Order' do
    it 'returns details' do
      expect(subject.status).to eql 200
      expect(subject.payload.type).to eql 'review'
      expect(subject.payload.token).not_to be_empty
      expect(subject.payload.ticker).to eql 'aapl'
      expect(subject.payload.order_action).to eql :buy
      expect(subject.payload.quantity).to eql 10.0
      expect(subject.payload.expiration).to eql :day
      # expect(subject.payload.price_label).to eql 'Market'
      # expect(subject.payload.value_label).to eql subject.raw['orderDetails']['orderValueLabel']
      # expect(subject.payload.message).to eql subject.raw['orderDetails']['orderMessage']
      expect(subject.payload.last_price).to eql subject.raw[:instrument]['lastTrade'].to_f
      expect(subject.payload.bid_price).to eql subject.raw[:instrument]['rateBid'].to_f
      expect(subject.payload.ask_price).to eql subject.raw[:instrument]['rateAsk'].to_f
      expect(subject.payload.estimated_commission).to eql subject.raw[:commission].to_f
      expect(subject.payload.estimated_value).to eql subject.raw[:instrument]['rateAsk'].to_f * quantity
      expect(subject.payload.estimated_total).to eql subject.payload.estimated_value + subject.raw[:commission].to_f
      expect(subject.payload.buying_power).to eql subject.raw[:account]['rtCashAvailForTrading'].to_f
    end
  end

  describe 'Sell Order' do
    let(:order_action) { :sell }
    it 'returns details' do
      expect(subject.payload.order_action).to eql :sell
    end
  end

  describe 'Not enough buying power' do
    let(:quantity) { 10000 }
    it 'raises error' do
      expect { subject }.to raise_error(Trading::Errors::OrderException)
    end
  end

  describe 'Buy to Cover Order' do
    let(:order_action) { :buy_to_cover }
    it 'returns details' do
      expect(subject.payload.order_action).to eql :buy_to_cover
    end
  end
  describe 'Sell Short Order' do
    let(:order_action) { :sell_short }
    it 'returns details' do
      expect(subject.payload.order_action).to eql :sell_short
    end
  end

  describe 'Market Buy with Amount' do
    let(:quantity) { 999.99 }
    let(:order_extras) do
      {
        amount: 10.0
      }
    end
    it 'returns details' do
      expect(subject.payload.amount).to eql 10.0
      expect(subject.payload.quantity).to eql 0.0
      expect(subject.payload.estimated_value).to eql 10.0
    end
  end

  describe 'for a stock that is not supported' do
    let(:ticker) { 'srne' }

    it 'throws error' do
      expect { subject }.to raise_error(Trading::Errors::OrderException)
    end
  end

  describe 'Sell more than you own' do
    let(:ticker) { 'aapl' }
    let(:order_action) { :sell }
    let(:quantity) { 500 }

    it 'throws error' do
      expect { subject }.to raise_error(Trading::Errors::OrderException)
    end
  end

  describe 'Amount and not Market' do
    let(:order_extras) do
      {
        amount: 10
      }
    end
    let(:price_type) { :limit }
    it 'throws error' do
      expect { subject }.to raise_error(Trading::Errors::OrderException)
    end
  end

  # describe 'price types' do
  # let(:order_extras) do
  #   {
  #     limit_price: 11.0
  #   }
  # end
  # describe 'limit' do
  #   let(:price_type) { :limit }
  #   it 'returns details' do
  #     expect(subject.status).to eql 200
  #     expect(subject.payload.type).to eql 'review'
  #     expect(subject.payload.price_label).to eql '$11.00'
  #   end
  # end

  # describe 'stop_market' do
  #   let(:order_extras) do
  #     {
  #       stop_price: 11.0
  #     }
  #   end
  #   let(:price_type) { :stop_market }
  #   it 'returns details' do
  #     expect(subject.status).to eql 200
  #     expect(subject.payload.type).to eql 'review'
  #     expect(subject.payload.price_label).to eql 'Market (trigger: $11.00)'
  #   end
  # end

  # describe 'stop_limit' do
  #   let(:order_extras) do
  #     {
  #       stop_price: 10.0,
  #       limit_price: 11.0
  #     }
  #   end
  #   let(:price_type) { :stop_limit }
  #   it 'returns details' do
  #     expect(subject.status).to eql 200
  #     expect(subject.payload.type).to eql 'review'
  #     expect(subject.payload.price_label).to eql '$11.00 (trigger: $10.00)'
  #   end
  # end
  # end

  # describe 'order that fails' do
  #   # Quantity above 100 will trigger errors with the test user
  #   let(:quantity) { 50 }
  #   it 'throws error' do
  #     expect { subject }.to raise_error(Trading::Errors::OrderException)
  #   end
  # end

  #
  # This is not available with the Zerodha Test users
  #
  # describe 'order_expirations' do
  #   let(:order_expiration) { :gtc }
  #   it 'returns details' do
  #     expect(subject.status).to eql 200
  #     expect(subject.payload.type).to eql 'review'
  #     expect(subject.payload.expiration).to eql :gtc
  #   end
  # end

  describe 'bad token' do
    let(:token) { 'foooooobaaarrrr' }
    it 'throws error' do
      expect { subject }.to raise_error(Trading::Errors::LoginException)
    end
  end
  describe 'bad account' do
    let(:account_number) { 'foooooobaaarrrr' }
    it 'throws error' do
      expect { subject }.to raise_error(Trading::Errors::LoginException)
    end
  end
end
