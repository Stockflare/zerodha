module Zerodha
  module User
    class Logout < Zerodha::Base
      values do
        attribute :token, String
      end

      def call
        uri = URI.join(Zerodha.api_uri, "session/token?api_key=#{Zerodha.api_key}&access_token=#{token}")

        req = Net::HTTP::Delete.new(uri, initheader = {
                                      'Content-Type' => 'application/json'
                                    })

        resp = Zerodha.call_api(uri, req)

        result = JSON.parse(resp.body)

        if resp.code == '200'
          self.response = Zerodha::Base::Response.new(raw: result,
                                                          status: 200,
                                                          payload: {
                                                            type: 'success',
                                                            accounts: [],
                                                            token: token
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
