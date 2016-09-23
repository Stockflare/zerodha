require 'spec_helper'

describe Zerodha::Positions::Get do
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

  subject do
    Zerodha::Positions::Get.new(
      token: token,
      account_number: account_number
    ).call.response
  end

  describe 'Get' do
    it 'returns positions' do
      expect(subject.status).to eql 200
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
