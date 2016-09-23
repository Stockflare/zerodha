module Zerodha
  module User
    class Verify < Zerodha::Base
      values do
        attribute :token, String
        attribute :answer, String
      end
      # Zerodha does not support this interraction, we will simply get an return the current session

      def call
        self.response = Zerodha::User::Login.new(
          user_id: '',
          user_token: token
        ).call.response

        self
      end
    end
  end
end
