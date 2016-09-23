module Zerodha
  module User
    class LinkAndLogin < Zerodha::Base
      values do
        attribute :broker, Symbol
        attribute :username, String
        attribute :password, String
      end

      def call
        link = Zerodha::User::Link.new(
          broker: broker,
          username: username,
          password: password
        ).call.response

        self.response = Zerodha::User::Login.new(
          user_id: link.payload[:user_id],
          user_token: link.payload[:user_token]
        ).call.response

        self
      end
    end
  end
end
