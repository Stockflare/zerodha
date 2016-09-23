module Zerodha
  module User
    class Refresh < Zerodha::Base
      values do
        attribute :token, String
      end

      def call
        # Drivewealth advise that this call is not needed so being bypassed 09/08/2016
        # uri = URI.join(Zerodha.api_uri, "v1/userSessions/#{token}?action=heartbeat")
        #
        #
        # req = Net::HTTP::Put.new(uri, initheader = {
        #                            'Content-Type' => 'application/json',
        #                            'x-mysolomeo-session-key' => token
        #                          })
        #
        # resp = Zerodha.call_api(uri, req)
        # result = JSON.parse(resp.body)

        # if resp.code == '200'
        if 1 == 1
          self.response = Zerodha::User::Login.new(
            user_id: '',
            user_token: token
          ).call.response
        else
          raise Trading::Errors::LoginException.new(
            type: :error,
            code: resp.code,
            description: 'Cannot Heartbeat Session',
            messages: 'Cannot Heartbeat Session'
          )
        end

        Zerodha.logger.info response.to_h
        self
      end
    end
  end
end
