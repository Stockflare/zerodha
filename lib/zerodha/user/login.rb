module Zerodha
  module User
    class Login < Zerodha::Base
      values do
        attribute :user_id, String
        attribute :user_token, String
      end

      def call
        uri = URI.join(Zerodha.api_uri, "user/margins/equity?api_key=#{Zerodha.api_key}&access_token=#{user_token}")

        req = Net::HTTP::Get.new(uri, initheader = {
                                   'Content-Type' => 'application/json'
                                 })

        resp = Zerodha.call_api(uri, req)
        result = JSON.parse(resp.body)

        if resp.code == '200'
          account = Zerodha::Base::Account.new(
            account_number: user_id,
            name: user_id
          ).to_h
          self.response = Zerodha::Base::Response.new(raw: result,
                                                          status: 200,
                                                          payload: {
                                                            type: 'success',
                                                            token: user_token,
                                                            accounts: [account]
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
