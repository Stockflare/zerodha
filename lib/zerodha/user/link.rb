require 'digest'

module Zerodha
  module User
    class Link < Zerodha::Base
      values do
        attribute :broker, Symbol
        attribute :username, String
        attribute :password, String
      end


      # Zerodha uses a redirect based login system.  in this integration we do not make use of username and the password
      # provided by api-trade will in fact be the post login request_token that has been provided by the Zerodha login flow
      # https://kite.trade/docs/connect/v1/#authentication
      def call
        checksum = Digest::SHA256.hexdigest "#{Zerodha.api_key}#{password}#{Zerodha.api_secret}"
        uri =  URI.join(Zerodha.api_uri, 'session/token')
        body = {
          'api_key' => Zerodha.api_key,
          'request_token' => password,
          'checksum' => checksum
        }

        resp = Net::HTTP.post_form(uri, body)
        result = JSON.parse(resp.body)
        
        if resp.code == '200'

          self.response = Zerodha::Base::Response.new(raw: result,
                                                          status: 200,
                                                          payload: {
                                                            type: 'success',
                                                            user_id: result['data']['user_id'],
                                                            user_token: result['data']['access_token']
                                                          },
                                                          messages: ['success'])
        else
          raise Trading::Errors::LoginException.new(
            type: :error,
            code: resp.code,
            description: result['message'],
            messages: result['message']
          )
        end
        # pp response.to_h
        Zerodha.logger.info response.to_h
        self
      end
    end
  end
end
