require 'spec_helper'

describe Zerodha::Order::Cancel do
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

  let(:placed_order) do
    Zerodha::Order::Place.new(
      token: preview_token,
      price: price
    ).call.response.payload
  end

  describe 'Cancel Order' do
    let(:orders) do
      Zerodha::Order::Status.new(
        token: token,
        account_number: account_number,
        order_number: order_number
      ).call.response.payload.orders
    end
    let(:order_number) { placed_order.order_number }

    subject do
      Zerodha::Order::Cancel.new(
        token: token,
        account_number: account_number,
        order_number: order_number
      ).call.response
    end

    it 'returns details' do
      expect(subject.status).to eql 200
      expect(subject.payload.type).to eql 'success'
      expect(subject.payload.token).not_to be_empty
      expect(subject.payload.orders[0].ticker).to eql 'ftfy'
      expect(subject.payload.orders[0].order_action).to eql :buy
      expect(subject.payload.orders[0].filled_quantity).to eql 0
      expect(subject.payload.orders[0].filled_price).to eql 0.0
      expect(subject.payload.orders[0].quantity).to eql 275_000
      expect(subject.payload.orders[0].expiration).to eql :gtc
    end
  end
end
