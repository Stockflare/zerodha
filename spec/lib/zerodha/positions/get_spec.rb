require 'spec_helper'

describe Zerodha::Positions::Get do
  let(:username) { 'DH0490' }
  let(:password) { 'na' }
  let(:account_number) { 'na' }
  let(:token) { ENV['RSPEC_SESSION_TOKEN'] }
  let(:broker) { :zerodha }

  let(:holdings_result) do
    {
      "status" => "success",
      "data" => [{
        "tradingsymbol" => "ABHICAP",
        "exchange" => "BSE",
        "isin" => "INE516F01016",
        "quantity" => 0,
        "realised_quantity" => 1,
        "t1_quantity" => 1,

        "average_price" => 94.75,
        "last_price" => 93.75,
        "pnl" => -100.0,

        "product" => "CNC",
        "collateral_quantity" => 0,
        "collateral_type" => nil
      }, {
        "tradingsymbol" => "AXISBANK",
        "exchange" => "NSE",
        "isin" => "INE238A01034",
        "quantity" => 1,
        "realised_quantity" => 1,
        "t1_quantity" => 0,

        "average_price" => 475.0,
        "last_price" => 432.55,
        "pnl" => -42.50,

        "product" => "CNC",
        "collateral_quantity" => 0,
        "collateral_type" => nil
      }]
    }
  end
  let(:positions_result) do
    {
      "status" => "success",
      "data" => {
        "net" => [{
          "tradingsymbol" => "NIFTY15DEC9500CE",
          "exchange" => "NFO",
          "instrument_token" => 41453,
          "product" => "NRML",

          "quantity" => -100,
          "overnight_quantity" => -100,
          "multiplier" => 1,

          "average_price" => 3.475,
          "close_price" => 0.75,
          "last_price" => 0.75,
          "net_value" => 75.0,
          "pnl" => 272.5,
          "m2m" => 0.0,
          "unrealised" => 0.0,
          "realised" => 0.0,

          "buy_quantity" => 0,
          "buy_price" => 0,
          "buy_value" => 0.0,
          "buy_m2m" => 0.0,

          "sell_quantity" => 100,
          "sell_price" => 3.475,
          "sell_value" => 347.5,
          "sell_m2m" => 75.0
        }],
        "day" => []
      }
    }
  end
  before do
    allow(Zerodha::User::Account).to receive(:holdings_result).and_return(holdings_result)
    allow(Zerodha::User::Account).to receive(:positions_result).and_return(positions_result)
  end
  
  subject do
    Zerodha::Positions::Get.new(
      token: token,
      account_number: account_number
    ).call.response
  end

  describe 'Get' do
    it 'returns positions' do
      expect(subject.status).to eql 200
      pp subject.to_h
      expect(subject.payload.positions.count).to be > 0
      expect(subject.payload.pages).to be > 0
      expect(subject.payload.positions[0].quantity).to_not eql 0
      expect(subject.payload.positions[0].quantity).to_not eql nil
      expect(subject.payload.positions[0].cost_basis).to_not eql 0
      expect(subject.payload.positions[0].cost_basis).to_not eql nil
      expect(subject.payload.token).not_to be_empty
    end
  end

  describe 'bad account' do
    let(:account_number) { 'foooooobaaarrrr' }
    it 'throws error' do
      expect { subject }.to raise_error(Trading::Errors::LoginException)
    end
  end
end
