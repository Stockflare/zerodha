require 'zerodha/version'

require 'multi_json'
require 'yajl/json_gem'
require 'virtus'
require 'httparty'
require 'trading'

module Zerodha
  autoload :Base, 'zerodha/base'
  autoload :User, 'zerodha/user'
  autoload :Positions, 'zerodha/positions'
  autoload :Order, 'zerodha/order'
  autoload :Instrument, 'zerodha/instrument'

  CACHE_PREFIX = 'zerodha_preview'

  class << self

    attr_writer :logger, :api_uri, :referral_code, :language, :cache

    # Helper to configure .
    #
    # @yield [Odin] Yields the {Zerodha} module.
    def configure
      yield self
    end

    # Zerodha order statuses
    def order_statuses
      {
        '0' => :pending,
        'OPEN' => :open,
        '2' => :filled,
        '1' => :filling,
        '4' => :cancelled,
        '8' => :rejected,
        'NOT_FOUND' => :not_found,
        'PENDING_CANCEL' => :pending_cancel,
        'EXPIRED' => :expired
      }
    end

    # Zerodha brokers as symbols
    def brokers
      {
        zerodha: 'Zerodha'
      }
    end

    # Zerodha order actions
    def order_actions
      {
        buy: 'B',
        sell: 'S',
        buy_to_cover: 'FORCE_ERROR',
        sell_short: 'FORCE_ERROR'
      }
    end

    def preview_order_actions
      {
        buy: 'Buy',
        sell: 'Sell',
        buy_to_cover: 'Buy to Cover',
        sell_short: 'Sell Short'
      }
    end

    def order_status_actions
      {
        'B' => :buy,
        'S' => :sell
      }
    end

    def place_order_actions
      {
        buy: 'B',
        sell: 'S',
        buy_to_cover: 'FORCE_ERROR',
        sell_short: 'FORCE_ERROR'
      }
    end

    # Zerodha price types
    def price_types
      {
        market: '1',
        limit: '2',
        stop_market: '3',
        stop_limit: 'FORCE_ERROR'
      }
    end

    # Zerodha order expirations
    def order_expirations
      {
        day: 'day',
        gtc: 'gtc'
      }
    end

    def order_status_expirations
      {
        'DAY' => :day,
        'GTC' => :gtc,
        'GOOD_TROUGH_DATE' => :gtd,
        'UNKNOWN' => :unknown
      }
    end

    def preview_order_expirations
      {
        day: 'Day',
        gtc: 'Good Till Cancelled'
      }
    end

    def api_uri
      if @api_uri
        return @api_uri
      else
        raise Trading::Errors::ConfigException.new(
          type: :error,
          code: 500,
          description: 'api_uri missing',
          messages: ['api_uri configuration variable has not been set']
        )
      end
    end

    def referral_code
      if @referral_code
        return @referral_code
      else
        raise Trading::Errors::ConfigException.new(
          type: :error,
          code: 500,
          description: 'referral_code missing',
          messages: ['referral_code configuration variable has not been set']
        )
      end
    end

    def language
      if @language
        return @language
      else
        raise Trading::Errors::ConfigException.new(
          type: :error,
          code: 500,
          description: 'language missing',
          messages: ['language configuration variable has not been set']
        )
      end
    end

    def cache
      if @cache
        return @cache
      else
        raise Trading::Errors::ConfigException.new(
          type: :error,
          code: 500,
          description: 'cache missing',
          messages: ['cache configuration variable has not been set']
        )
      end
    end

    def logger
      @logger ||= Logger.new($stdout).tap do |log|
        log.progname = name
      end
    end

    def call_api(uri, req)
      Net::HTTP.start(uri.hostname, uri.port,
                      use_ssl: uri.scheme == 'https') do |http|
        http.request(req)
      end
    end
  end
end
