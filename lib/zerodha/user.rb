# User based actions fro the Zerodha API
#
#
module Zerodha
  module User
    autoload :Link, 'zerodha/user/link'
    autoload :Login, 'zerodha/user/login'
    autoload :LinkAndLogin, 'zerodha/user/link_and_login'
    autoload :Verify, 'zerodha/user/verify'
    autoload :Logout, 'zerodha/user/logout'
    autoload :Refresh, 'zerodha/user/refresh'
    autoload :Account, 'zerodha/user/account'

    class << self
      #
      # Parse a Zerodha Login or Verify response into our format
      #
      def parse_result(result, resp)
        if resp.code == '200'
          #
          # User logged in without any security questions
          #
          accounts = []
          if result['accounts']
            accounts = result['accounts'].map do |a|
              Zerodha::Base::Account.new(
                account_number: a['accountNo'],
                name: a['nickname']
              ).to_h
            end
          end
          response = Zerodha::Base::Response.new(raw: result,
                                                     status: 200,
                                                     payload: {
                                                       type: 'success',
                                                       token: result['sessionKey'],
                                                       accounts: accounts
                                                     },
                                                     messages: ['success'])

        else
          #
          # Login failed
          #
          raise Trading::Errors::LoginException.new(
            type: :error,
            code: resp.code,
            description: result['message'],
            messages: result['message']
          )
        end

        # pp(response.to_h)
        response
      end

      #
      # Get a User and Account Details from a session token
      #
      def get_user_from_token(token)
        # Heartbeat the session in order to get the user id
        result = Zerodha::User::Refresh.new(
          token: token
        ).call.response
        user_id = result.raw['userID']

        if user_id
          return result
        else
          raise Trading::Errors::LoginException.new(
            type: :error,
            code: '403',
            description: 'User could not be found',
            messages: 'User could not be found'
          )
        end
      end

    end
  end
end
