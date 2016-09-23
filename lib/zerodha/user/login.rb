module Zerodha
  module User
    class Login < Zerodha::Base
      values do
        attribute :user_id, String
        attribute :user_token, String
      end

      def call
        uri = URI.join(Zerodha.api_uri, "v1/userSessions/#{user_token}")

        req = Net::HTTP::Get.new(uri, initheader = {
                                   'Content-Type' => 'application/json',
                                   'x-mysolomeo-session-key' => user_token
                                 })

        resp = Zerodha.call_api(uri, req)

        result = JSON.parse(resp.body)

        self.response = Zerodha::User.parse_result(result, resp)

        Zerodha.logger.info response.to_h
        self
      end
    end
  end
end
