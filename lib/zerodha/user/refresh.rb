module Zerodha
  module User
    class Refresh < Zerodha::Base
      values do
        attribute :token, String
      end

      def call
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
