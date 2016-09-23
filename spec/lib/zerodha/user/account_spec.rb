require 'spec_helper'

describe Zerodha::User::Account do
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

  describe 'Get Account' do
    subject do
      Zerodha::User::Account.new(
        token: token,
        account_number: account_number
      ).call.response
    end
    it 'returns details' do
      expect(subject.status).to eql 200
      expect(subject.payload.cash).not_to eql 0.0
      expect(subject.payload.token).not_to be_empty
      expect(subject.payload.power).not_to eql 0.0
      expect(subject.payload.day_return).not_to eql 0.0
      expect(subject.payload.day_return_percent).not_to eql 0.0
      expect(subject.payload.total_return).not_to eql 0.0
      expect(subject.payload.total_return_percent).not_to eql 0.0
      expect(subject.payload.value).not_to eql 0.0
    end
    describe 'bad token' do
      let(:token) { 'foooooobaaarrrr' }
      it 'throws error' do
        expect { subject }.to raise_error(Trading::Errors::LoginException)
      end
    end
  end
end
