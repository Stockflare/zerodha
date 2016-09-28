require 'spec_helper'

describe Zerodha::User::Link do
  let(:username) { 'na' }
  let(:password) { 'fi21zo8lsxheqj9pdvlix4hf4lenvusn' }
  let(:broker) { :zerodha }

  subject do
    Zerodha::User::Link.new(
      username: username,
      password: password,
      broker: broker
    ).call.response
  end

  describe 'good credentials' do
    it 'returns token' do
      expect(subject.status).to eql 200
      pp subject.to_h
      expect(subject.payload.type).to eql 'success'
      expect(subject.payload.user_token).not_to be_empty
      expect(subject.payload.user_id).not_to be_empty
    end
  end

  describe 'bad credentials' do
    let(:password) { 'foooooobaaarrrr' }
    it 'throws error' do
      expect { subject }.to raise_error(Trading::Errors::LoginException)
    end
  end
end
