require 'spec_helper'

describe Zerodha::User::Refresh do
  let(:username) { 'DH0490' }
  let(:password) { 'na' }
  let(:token) { ENV['RSPEC_SESSION_TOKEN'] }
  let(:broker) { :zerodha }

  subject do
    Zerodha::User::Refresh.new(
      token: token
    ).call.response
  end

  describe 'good logout' do
    it 'returns token' do
      expect(subject.status).to eql 200
      expect(subject.payload.type).to eql 'success'
      expect(subject.payload.token).not_to be_empty
      expect(subject.payload.token).to eql token
    end
  end

  describe 'bad token' do
    let(:token) { 'foooooobaaarrrr' }
    it 'throws error' do
      expect { subject }.to raise_error(Trading::Errors::LoginException)
    end
  end
end
