require "zlib"
module Zerodha
  module Instrument
    class List < Zerodha::Base

      def call
        result = nil

        cached = Zerodha.cache.get("#{Zerodha::CACHE_PREFIX}_InstrumentList")
        if cached
          result = JSON.parse(Zlib::Inflate.inflate(cached))
        end

        if !result
          uri = URI.join(Zerodha.api_uri, "instruments?api_key=#{Zerodha.api_key}")

          req = Net::HTTP::Get.new(uri, initheader = {
                                     'Content-Type' => 'text/csv',
                                     'Content-Encoding' => 'gzip'
                                   })

          resp = Zerodha.call_api(uri, req)
          result = {

          }
          CSV.parse(resp.body, headers: true) do |row|
            result[row['tradingsymbol']] = {
              'exchange' => row['exchange']
            }
          end
        end

        if cached || resp.code == '200'

          # Cache the result for 24 hours
          Zerodha.cache.set("#{Zerodha::CACHE_PREFIX}_InstrumentList", Zlib::Deflate.deflate(result.to_json), 86400)
          self.response = Zerodha::Base::Response.new(raw: [],
                                                          status: 200,
                                                          payload: {
                                                            type: 'success',
                                                            list: result
                                                          },
                                                          messages: ['success'])
        else
          raise Trading::Errors::LoginException.new(
            type: :error,
            code: resp.code,
            description: 'Could not get instrument list',
            messages: ['Could not get instrument list']
          )
        end
        # pp response.to_h
        # Zerodha.logger.info response.to_h
        self
      end

    end
  end
end
