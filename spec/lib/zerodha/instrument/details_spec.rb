require 'spec_helper'

describe Zerodha::Instrument::Details do
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

  let(:ticker) { 'aapl' }

  subject do
    Zerodha::Instrument::Details.new(
      token: token,
      ticker: ticker
    ).call.response
  end

  describe 'Details' do
    it 'returns positions' do
      expect(subject.status).to eql 200
      expect(subject.payload.type).to eql 'success'
      expect(subject.payload.broker_id).not_to be_empty
      expect(subject.payload.last_price).to be > 0.0
      expect(subject.payload.last_price).to be > 0.0
      expect(subject.payload.bid_price).to be > 0.0
      expect(subject.payload.ask_price).to be > 0.0
      expect(subject.payload.order_size_max).to be > 0.0
      expect(subject.payload.order_size_min).to be > 0.0
      expect(subject.payload.order_size_step).to be > 0.0
      expect(subject.payload.timestamp).to be > 0
      expect(subject.payload.allow_fractional_shares).to eql true
      expect(subject.payload.token).not_to be_empty
    end
  end

  describe 'bad tiocker' do
    let(:ticker) { 'foooooobaaarrrr' }
    it 'throws error' do
      expect { subject }.to raise_error(Trading::Errors::OrderException)
    end
  end  

end
