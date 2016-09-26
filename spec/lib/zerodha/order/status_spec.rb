require 'spec_helper'

describe Zerodha::Order::Status do
  let(:username) { 'DH0490' }
  let(:password) { 'na' }
  let(:token) { ENV['RSPEC_SESSION_TOKEN'] }
  let(:broker) { :zerodha }
  let(:account_number) { 'na' }

  let(:result) do
    {
      "status" => "success",
      "data" => [
        {
          "order_id" => "151220000000000",
          "parent_order_id" => "151210000000000",
          "exchange_order_id" => nil,
          "placed_by" => "AB0012",
          "variety" => "regular",
          "status" => "COMPLETE",
          "tradingsymbol" => "ACC",
          "exchange" => "NSE",
          "instrument_token" => 22,
          "transaction_type" => "BUY",
          "order_type" => "MARKET",
          "product" => "NRML",
          "validity" => "DAY",
          "price" => 0.10,
          "quantity" => 75,
          "trigger_price" => 0.0,
          "average_price" => 0.10,
          "pending_quantity" => 0,
          "filled_quantity" => 10,
          "disclosed_quantity" => 0,
          "market_protection" => 0,
          "order_timestamp" => "2015-12-20 15:01:43",
          "exchange_timestamp" => nil,
          "status_message" => "RMS:Margin Exceeds, Required:0, Available:0"
        },
        {
          "order_id" => "151220000000099",
          "parent_order_id" => "151210000000000",
          "exchange_order_id" => nil,
          "placed_by" => "AB0012",
          "variety" => "regular",
          "status" => "COMPLETE",
          "tradingsymbol" => "ACC",
          "exchange" => "NSE",
          "instrument_token" => 22,
          "transaction_type" => "BUY",
          "order_type" => "MARKET",
          "product" => "NRML",
          "validity" => "DAY",
          "price" => 0.99,
          "quantity" => 75,
          "trigger_price" => 0.0,
          "average_price" => 0.99,
          "pending_quantity" => 0,
          "filled_quantity" => 10,
          "disclosed_quantity" => 0,
          "market_protection" => 0,
          "order_timestamp" => "2015-12-20 15:01:43",
          "exchange_timestamp" => nil,
          "status_message" => "RMS:Margin Exceeds, Required:0, Available:0"
        }
      ]
    }
  end

  before do
    allow(Zerodha::Order::Status).to receive(:result).and_return(result)
  end

  describe 'All Order Status' do
    subject do
      Zerodha::Order::Status.new(
        token: token,
        account_number: account_number
      ).call.response
    end
    it 'returns details' do
      expect(subject.status).to eql 200
      pp subject.to_h
      expect(subject.payload.type).to eql 'success'
      expect(subject.payload.token).not_to be_empty
      expect(subject.payload.orders[0].ticker).not_to be_empty
      expect(subject.payload.orders[0].order_action).to eql :buy
      expect(subject.payload.orders[0].filled_quantity).to be > 0
      expect(subject.payload.orders[0].filled_price).to be > 0
      expect(subject.payload.orders[0].quantity).to be > 0
      expect(subject.payload.orders[0].expiration).to eql :day
      expect(subject.payload.orders[0].status).to eql :filled
    end
    describe 'bad token' do
      let(:token) { 'foooooobaaarrrr' }
      it 'throws error' do
        expect { subject }.to raise_error(Trading::Errors::OrderException)
      end
    end
  end

  describe 'Single Order Status' do
    let(:orders) do
      Zerodha::Order::Status.new(
        token: token,
        account_number: account_number
      ).call.response.payload.orders
    end
    let(:order_number) { '151220000000099' }

    subject do
      Zerodha::Order::Status.new(
        token: token,
        account_number: account_number,
        order_number: order_number
      ).call.response
    end

    it 'returns details' do
      # expect(placed_order.status).to eql 200
      expect(subject.status).to eql 200
      expect(subject.payload.type).to eql 'success'
      expect(subject.payload.token).not_to be_empty
      expect(subject.payload.orders[0].order_number).not_to be_empty
      expect(subject.payload.orders[0].order_number).to eql order_number
    end
    describe 'bad account' do
      let(:token) { 'foooooobaaarrrr' }
      it 'throws error' do
        expect { subject }.to raise_error(Trading::Errors::OrderException)
      end
    end
  end
end
