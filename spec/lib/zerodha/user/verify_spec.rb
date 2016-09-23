require 'spec_helper'

describe Zerodha::User::Verify do
  let(:username) { 'stockflare.ff' }
  let(:password) { 'passw0rd' }
  let(:broker) { :zerodha }
  let(:answer) { 'tradingticket' }
  let!(:user) do
    Zerodha::User::LinkAndLogin.new(
      username: username,
      password: password,
      broker: broker
    ).call.response.payload
  end
  let(:token) { user[:token] }

  subject do
    Zerodha::User::Verify.new(
      token: token,
      answer: answer
    ).call.response
  end

  describe 'good answer' do
    it 'returns token' do
      expect(subject.status).to eql 200
      expect(subject.payload.type).to eql 'success'
      expect(subject.payload.token).not_to be_empty
    end
  end

  describe 'bad token' do
    let(:token) { 'foooooobaaarrrr' }
    it 'throws error' do
      expect { subject }.to raise_error(Trading::Errors::LoginException)
    end
  end

  # describe 'user needing security question' do
  #   let(:answer) { 'foooooobaaarrrr' }
  #   it 'returns response with questions' do
  #     expect(subject.payload.type).to eql 'verify'
  #     expect(subject.payload.challenge).to eql 'question'
  #     expect(subject.payload.data).to have_key :answers
  #   end
  # end
end
