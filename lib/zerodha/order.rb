# User based actions fro the Zerodha API
#
#
module Zerodha
  module Order
    autoload :Preview, 'zerodha/order/preview'
    autoload :Place, 'zerodha/order/place'
    autoload :Status, 'zerodha/order/status'
    autoload :Cancel, 'zerodha/order/cancel'

    class << self
    end
  end
end
