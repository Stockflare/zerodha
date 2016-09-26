require 'spec_helper'

describe Zerodha::Order::Place do

  subject do
    Zerodha::Order::Place.new.call.response
  end

  describe 'Raises' do
    it 'unsupported error' do
      expect { subject }.to raise_error(Trading::Errors::OrderException)
    end
  end
end
