require 'spec_helper'

describe Zerodha::Order::Preview do

  subject do
    Zerodha::Order::Preview.new.call.response
  end

  describe 'Raises' do
    it 'unsupported error' do
      expect { subject }.to raise_error(Trading::Errors::OrderException)
    end
  end
end
