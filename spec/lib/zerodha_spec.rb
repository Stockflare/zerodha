require 'spec_helper'

describe Zerodha do
  it 'has a version number' do
    expect(Zerodha::VERSION).not_to be nil
  end

  it 'returns brokers' do
    expect(Zerodha.brokers[:zerodha]).to eq('Zerodha')
  end

  describe '#api_uri' do
    it 'returns ENV - DRIVE_WEALTH_BASE_URI' do
      expect(Zerodha.api_uri).to eql ENV['DRIVE_WEALTH_BASE_URI']
    end
    it 'raises error when not configured' do
      Zerodha.configure do |config|
        config.api_uri = nil
      end
      expect { Zerodha.api_uri }.to raise_error(Trading::Errors::ConfigException)
    end
  end
  describe '#referral_code' do
    it 'returns ENV - Zerodha_BASE_URI' do
      expect(Zerodha.referral_code).to eql ENV['DRIVE_WEALTH_REFERRAL_CODE']
    end
    it 'raises error when not configured' do
      Zerodha.configure do |config|
        config.referral_code = nil
      end
      expect { Zerodha.referral_code }.to raise_error(Trading::Errors::ConfigException)
    end
  end
  describe '#language' do
    it 'returns ENV - DRIVE_WEALTH_LANGUAGE' do
      expect(Zerodha.language).to eql ENV['DRIVE_WEALTH_LANGUAGE']
    end
    it 'raises error when not configured' do
      Zerodha.configure do |config|
        config.language = nil
      end
      expect { Zerodha.language }.to raise_error(Trading::Errors::ConfigException)
    end
  end

  # describe '#cache' do
  #   it 'returns An instance of Memcached' do
  #     expect(Zerodha.cache).to eql an_instance_of(Memcached)
  #   end
  #   it 'raises error when not configured' do
  #     Zerodha.configure do |config|
  #       config.cache = nil
  #     end
  #     expect { Zerodha.cache }.to raise_error(Trading::Errors::ConfigException)
  #   end
  # end
end
