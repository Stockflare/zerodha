require 'spec_helper'

describe Zerodha::Instrument::Details do

  subject do
    Zerodha::Order::Details.new.call.response
  end

  describe 'Raises' do
    it 'unsupported error' do
      expect { subject }.to raise_error(Trading::Errors::OrderException)
    end
  end
end
