require 'spec_helper'

describe Zerodha::Order::Place do
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
  let(:base_order) do
    {
      token: token,
      account_number: account_number,
      order_action: order_action,
      quantity: quantity,
      ticker: 'aapl',
      price_type: price_type,
      expiration: order_expiration
    }
  end
  let(:order_extras) do
    {}
  end

  let(:price) { 123.45 }

  let!(:preview) do
    Zerodha::Order::Preview.new(
      base_order.merge(order_extras)
    ).call.response.payload
  end

  let(:preview_token) { preview.token }

  subject do
    Zerodha::Order::Place.new(
      token: preview_token,
      price: price
    ).call.response
  end

  describe 'Buy Order' do
    it 'returns details' do
      expect(subject.status).to eql 200
      expect(subject.payload.type).to eql 'success'
      expect(subject.payload.token).not_to be_empty
      expect(subject.payload.ticker).to eql 'aapl'
      expect(subject.payload.order_action).to eql :buy
      expect(subject.payload.quantity).to eql 10.0
      expect(subject.payload.expiration).to eql :day
      expect(subject.payload.price_label).to eql 'Market'
      # expect(subject.payload.message).to eql subject.raw['confirmationMessage']
      expect(subject.payload.last_price).to be > 0
      expect(subject.payload.bid_price).to be > 0
      expect(subject.payload.ask_price).to be > 0
      expect(subject.payload.price_timestamp).to be > 0
      expect(subject.payload.timestamp).to be > 0
      expect(subject.payload.order_number).not_to be_empty
      expect(subject.payload.price).to eql price
    end
  end

  describe 'Sell Order' do
    let(:order_action) { :sell }
    it 'returns details' do
      expect(subject.payload.order_action).to eql :sell
    end
  end

  describe 'Buy Order with Amount' do
    let(:quantity) { 99.99 }
    let(:order_extras) do
      {
        amount: 500.0
      }
    end
    it 'returns details' do
      expect(subject.status).to eql 200
      expect(subject.payload.type).to eql 'success'
      expect(subject.payload.token).not_to be_empty
      expect(subject.payload.ticker).to eql 'aapl'
      expect(subject.payload.order_action).to eql :buy
      expect(subject.payload.quantity).not_to eql quantity
      expect(subject.payload.quantity).to eql 0.0
      expect(subject.payload.expiration).to eql :day
      expect(subject.payload.price_label).to eql 'Market'
      # expect(subject.payload.message).to eql subject.raw['confirmationMessage']
      expect(subject.payload.last_price).to be > 0
      expect(subject.payload.bid_price).to be > 0
      expect(subject.payload.ask_price).to be > 0
      expect(subject.payload.price_timestamp).to be > 0
      expect(subject.payload.timestamp).to be > 0
      expect(subject.payload.order_number).not_to be_empty
      expect(subject.payload.price).to eql price
    end
  end

  describe 'fractional shares' do
    let(:quantity) { 10.5 }
    it 'returns details' do
      expect(subject.status).to eql 200
      expect(subject.payload.type).to eql 'success'
      expect(subject.payload.token).not_to be_empty
      expect(subject.payload.ticker).to eql 'aapl'
      expect(subject.payload.order_action).to eql :buy
      expect(subject.payload.quantity).to eql 10.5
      expect(subject.payload.expiration).to eql :day
      expect(subject.payload.price_label).to eql 'Market'
      # expect(subject.payload.message).to eql subject.raw['confirmationMessage']
      expect(subject.payload.last_price).to be > 0
      expect(subject.payload.bid_price).to be > 0
      expect(subject.payload.ask_price).to be > 0
      expect(subject.payload.price_timestamp).to be > 0
      expect(subject.payload.timestamp).to be > 0
      expect(subject.payload.order_number).not_to be_empty
      expect(subject.payload.price).to eql price
    end
  end
  # describe 'Buy to Cover Order' do
  #   let(:order_action) { :buy_to_cover }
  #   it 'returns details' do
  #     expect(subject.payload.order_action).to eql :buy_to_cover
  #   end
  # end
  # describe 'Sell Short Order' do
  #   let(:order_action) { :sell_short }
  #   it 'returns details' do
  #     expect(subject.payload.order_action).to eql :sell_short
  #   end
  # end

  describe 'price types' do
    let(:order_extras) do
      {
        limit_price: 11.0
      }
    end
    describe 'limit' do
      let(:price_type) { :limit }
      it 'returns details' do
        expect(subject.status).to eql 200
        expect(subject.payload.type).to eql 'success'
        expect(subject.raw['limitPrice']).to eql price
        expect(subject.payload.price_label).to eql 'Limit'
      end
    end

    describe 'stop_market' do
      let(:order_extras) do
        {
          stop_price: 11.0
        }
      end
      let(:price_type) { :stop_market }
      it 'returns details' do
        expect(subject.status).to eql 200
        expect(subject.payload.type).to eql 'success'
        expect(subject.raw['limitPrice']).to eql 0.0
        expect(subject.payload.price_label).to eql 'Stop on Quote'
      end
    end

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
    #     expect(subject.payload.type).to eql 'success'
    #     expect(subject.payload.price_label).to eql 'Stop Limit on Quote'
    #   end
    # end

    describe 'failed place' do
      let(:preview_token) { 'foooooobaaarrrr' }
      it 'throws error' do
        expect { subject }.to raise_error(Trading::Errors::OrderException)
      end
    end
  end
end
