require 'spec_helper'

describe Zerodha::Instrument::List do
  let(:username) { 'DH0490' }
  let(:password) { 'na' }
  let(:user_token) { ENV['RSPEC_SESSION_TOKEN'] }
  let(:broker) { :zerodha }
  # let!(:link) do
  #   Zerodha::User::Link.new(
  #     username: username,
  #     password: password,
  #     broker: broker
  #   ).call.response
  # end
  # let(:user_id) { link.payload.user_id }
  # let(:user_token) { link.payload.user_token }

  subject do
    Zerodha::Instrument::List.new(
    ).call.response
  end

  describe 'Gets list' do
    it 'returns token' do
      expect(subject.status).to eql 200
      # pp subject.to_h
      expect(subject.payload.type).to eql 'success'
      expect(subject.payload.list['IBULHSGFIN-N1']['exchange']).to eql 'NSE'
    end
  end


end
