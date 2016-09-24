# Zerodha

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'zerodha', github: 'stockflare/zerodha', tag: '0.1.0'
```

## Usage

This Gem wraps all interactions with The [Zerodha](https://kite.trade/docs/connect/v1/#introduction) API into a format that is convenient for our own internal APIs.

Once installed all Zerodha actions are objects within the `Zerodha` module.  Each object is initialized with the parameters required for the Zerodha call and has one `call` method to execute the communications with Zerodha.  All objects return the result of the Zerodha interaction in a `response` attribute that supports `to_h`

It is expected that most Stockflare use cases will only use the `response.payload` as this is a parsed version of the Zerodha response suitable for Stockflare and it is this output that is tested.  For convenience the `response.payload` is delivered as a `Hashie::Mash` to allow for method based access, for instance you can can access the status of the call by using `response.payload.status`.

Additionally a `response.raw` is provided that contains the raw Zerodha response.  This is provided for development and debug purposes only.  Upstream users should only rely on the `response.payload` and `response.messages`.  This will allow us to deal with minor breaking changes in the Zerodha API (which is currently in QA) without having to make code changes in upstream users.

All Error cases are handled by raising a subclass of `Trading::Errors::ZerodhaException`, this object exposes a number of attributes that can you can `to_h` to the consumer.

### Configuration Values

Two attributes need to be set

```
Zerodha.configure do |config|
  config.api_uri = ENV['Zerodha_BASE_URI']
  config.api_key = ENV['Zerodha_API_KEY']
end
```

### Brokers

We current support the following broker symbols
```
{
  zerodha: 'Zerodha'
}
```

### Order Actions

```
{
  buy: 'buy',
  sell: 'sell',
  buy_to_cover: 'buyToCover',
  sell_short: 'sellShort'
}
```

### Price Types

```
{
  market: 'market',
  limit: 'limit',
  stop_market: 'stopMarket',
  stop_limit: 'stopLimit'
}
```

### Order Expirations
```
{
  day: 'day',
  gtc: 'gtc'
}
```

Note that the test user does not support type `:gtc`

### Zerodha::User::Link

Called with the request token provided by the Zerodha login redirect flow.  The username needs to be provided but can be anything, `api-trade` will use the returned `user_id` to create the link record as this is the only way for us to know what the Zerodha user id is.

Example Call:

```
Zerodha::User::Link.new(
  username: "na",
  password: <request_token>,
  broker: "zerodha"
).call.response
```

Successful response:

```
{:raw=>
  {"status"=>"success",
   "data"=>
    {"product"=>["BO", "CO", "CNC", "MIS", "NRML"],
     "user_id"=>"DH0490",
     "order_type"=>["LIMIT", "MARKET", "SL", "SL-M"],
     "exchange"=>
      ["BSE",
       "MCXSX",
       "MCXSXCM",
       "MCXSXFO",
       "BFO",
       "CDS",
       "MCX",
       "NSE",
       "NFO"],
     "access_token"=>"nuq1ubbufdlfmtpj7is9boa8svkdl1ul",
     "password_reset"=>false,
     "user_type"=>"investor",
     "broker"=>"ZERODHA",
     "public_token"=>"2056035def9a69360827c29cc8c46243",
     "member_id"=>"ZERODHA",
     "user_name"=>"HEMASUNDAR RAO",
     "email"=>"hemasundhar.rao@gmail.com",
     "login_time"=>"2016-09-23 17:08:57"}},
 :status=>200,
 :payload=>
  {"type"=>"success",
   "user_id"=>"DH0490",
   "user_token"=>"nuq1ubbufdlfmtpj7is9boa8svkdl1ul"},
 :messages=>["success"]}
```

Link failure will raise a `Trading::Errors::LoginException` with the following attributes:

```
{ type: :error,
  code: 500,
  description: 'Invalid session credentials',
  messages: ['Invalid session credentials'] }
```


### Zerodha::User::Login

With Zerodha, the user is already logged in by the `Link` call, this will in fact simply use to token to make a call to ensure that the token is still valid and is here to maintain compatibility with our Gem interface.

Zerodha users only have one `account` therefore this call will return synthesised account details where the `account_number` will be the `user_id`.

Note that the `token` emitted by this call will simply be a copy of the `user_token` sent to this call.

example call:

```
Zerodha::User::Login.new(
  user_id: user_id,
  user_token: user_token
).call.response
```

Successful response without security question:

```
{:raw=>
  {"status"=>"success",
   "data"=>
    {"available"=>
      {"adhoc_margin"=>0.0,
       "collateral"=>0.0,
       "intraday_payin"=>0.0,
       "cash"=>-1070.95},
     "net"=>-1070.95,
     "enabled"=>true,
     "utilised"=>
      {"m2m_unrealised"=>-0.0,
       "m2m_realised"=>-0.0,
       "debits"=>0.0,
       "span"=>0.0,
       "option_premium"=>0.0,
       "holding_sales"=>0.0,
       "exposure"=>0.0,
       "turnover"=>0.0}}},
 :status=>200,
 :payload=>
  {"type"=>"success",
   "token"=>"u6rrejn8kml03w6a55riftcz8bcuw45z",
   "accounts"=>
    [{"account_number"=>"DH0490",
      "name"=>"DH0490",
      "cash"=>nil,
      "power"=>nil,
      "day_return"=>nil,
      "day_return_percent"=>nil,
      "total_return"=>nil,
      "total_return_percent"=>nil,
      "value"=>nil}]},
 :messages=>["success"]}
```

Security Questions are not supported in Zerodha

Login failure will raise a `Trading::Errors::LoginException` with the following attributes:

```
{ type: :error,
  code: 500,
  description: 'Could Not Login',
  messages: ['Check your username and password and try again.'] }
```

### Zerodha::User::Verify

Zerodha does not support security questions.  A call to this endpoint will return results identical to `Zerodha::User::Login` regardless of the security answer provided

Example Call

```
Zerodha::User::Verify.new(
  token: <token from Zerodha::User::Login>,
  answer: answer
).call.response
```

All success responses are identical to `Zerodha::User::Login`

If the user provides a bad answer then the response will be a success asking another question.

A failure will raise a `Trading::Errors::LoginException` with the similar attributes:
```
{ type: :error,
  code: 500,
  description: 'Could Not Complete Your Request',
  messages: ['Your session has expired. Please try again'] }
```

### Zerodha::User::Account

Get the current financial state of an account

Example Call

```
Zerodha::User::Account.new(
  token: <token from Zerodha::User::Login>,
  account_number: account_number
).call.response
```

Example response

```
{:raw=>
  {"availableCash"=>1204.06,
   "buyingPower"=>2408.12,
   "dayAbsoluteReturn"=>78.42,
   "dayPercentReturn"=>3.25,
   "longMessages"=>nil,
   "shortMessage"=>"Account Overview successfully fetched",
   "status"=>"SUCCESS",
   "token"=>"3e40016b846f4d20a4b7102a1949f893",
   "totalAbsoluteReturn"=>14486.67,
   "totalPercentReturn"=>22.84,
   "totalValue"=>76489.23},
 :status=>200,
 :payload=>
  {"type"=>"success",
   "cash"=>1204.06,
   "power"=>2408.12,
   "day_return"=>78.42,
   "day_return_percent"=>3.25,
   "total_return"=>14486.67,
   "total_return_percent"=>22.84,
   "value"=>22.84,
   "token"=>"3e40016b846f4d20a4b7102a1949f893"},
 :messages=>["Account Overview successfully fetched"]}
```


A failure will raise a `Trading::Errors::LoginException` with the similar attributes:
```
{ type: :error,
  code: 500,
  description: 'Could Not Complete Your Request',
  messages: ['Your session has expired. Please try again'] }
```

### Zerodha::User::Logout

Example call:
```
Zerodha::User::Logout.new(
  token: <token from previous login>
).call.response
```

Successful logout response

```
{ raw: { 'longMessages' => nil, 'shortMessage' => nil, 'status' => 'SUCCESS', 'token' => '765b7e4056334a27a9b65033b889878e' },
  status: 200,
  payload: { type: 'success', token: '765b7e4056334a27a9b65033b889878e', accounts: nil },
  messages: [] }
```

Failed Logout will raise a `Trading::Errors::LoginException` with similar attributes:

```
{ type: :error,
  code: 500,
  description: 'Could Not Complete Your Request',
  messages: ['Your session has expired. Please try again'] }
```

### Zerodha::User::Refresh

Used to stop a users token from expiring, does not send you a new token

Example Call:

```
Zerodha::User::Refresh.new(
  token: token
).call.response
```

Response is identical to `Trade::User::Login`

Failed Logout will raise a `Trading::Errors::LoginException` with similar attributes:

```
{ type: :error,
  code: 500,
  description: 'Could Not Complete Your Request',
  messages: ['Your session has expired. Please try again'] }
```

### Zerodha::Position::Get

Example Call

```
Zerodha::Positions::Get.new(
  token: token,
  account_number: account_number
).call.response
```

Successful response:

```
{ raw:   { 'currentPage' => 0,
           'longMessages' => nil,
           'positions' =>
    [{ 'costbasis' => 103.34,
       'holdingType' => 'LONG',
       'lastPrice' => 112.34,
       'quantity' => 1.0,
       'symbol' => 'AAPL',
       'symbolClass' => 'EQUITY_OR_ETF',
       'todayGainLossDollar' => 3.0,
       'todayGainLossPercentage' => 0.34,
       'totalGainLossDollar' => 9.0,
       'totalGainLossPercentage' => 1.2 },
      ...
     ],
           'shortMessage' => 'Position successfully fetched',
           'status' => 'SUCCESS',
           'token' => 'd3e72226aad646cea9e2d6177bd50953',
           'totalPages' => 1 },
  status: 200,
  payload:   { positions:     [{ quantity: 1, price: 103.34, ticker: 'AAPL', instrument_class: 'equity_or_etf', change: 9.0, holding: 'long' },
                               { quantity: -1, price: 103.34, ticker: 'IBM', instrument_class: 'equity_or_etf', change: 9.0, holding: 'short' },
                               { quantity: 1, price: 103.34, ticker: 'GE', instrument_class: 'equity_or_etf', change: 9.0, holding: 'short' },
                               { quantity: 1, price: 103.34, ticker: 'MSFT', instrument_class: 'equity_or_etf', change: 9.0, holding: 'long' }],
               pages: 1,
               page: 0,
               token: d3e72226aad646cea9e2d6177bd50953},
  messages: ['Position successfully fetched'] }
```

Failed Call will raise a `Trading::Errors::PositionException` with similar attributes:

```
{ type: :error,
  code: 500,
  description: 'Could Not Fetch Your Positions',
  messages:   ['The account foooooobaaarrrr is not valid or not active anymore.'] }
```

### Zerodha::Order::Preview

Example call:

```
Zerodha::Order::Preview.new(
  token: token,
  account_number: account_number,
  order_action: :buy,
  quantity: 10,
  ticker: 'aapl',
  price_type: :market,
  expiration: :day,
  amount: 500,
).call.response
```

Successful response:

```
{ raw:   { 'ackWarningsList' => [],
           'longMessages' => nil,
           'orderDetails' =>
    { 'orderSymbol' => 'aapl',
      'orderAction' => 'Buy',
      'orderQuantity' => 10.0,
      'orderExpiration' => 'Day',
      'orderPrice' => 'Market',
      'orderValueLabel' => 'Estimated Cost',
      'orderMessage' => 'You are about to place a market order to buy AAPL',
      'lastPrice' => '19.0',
      'bidPrice' => '18.0',
      'askPrice' => '22.0',
      'timestamp' => 'Fri Feb 12 08:51:25 EST 2016',
      'estimatedOrderValue' => 25.0,
      'estimatedTotalValue' => 28.5,
      'buyingPower' => 1234.0,
      'longHoldings' => 12.0,
      'estimatedOrderCommission' => 3.5 },
           'orderId' => 1,
           'shortMessage' => nil,
           'status' => 'REVIEW_ORDER',
           'token' => '140784ef96214a5186041abebdfe038a',
           'warningsList' => [] },
  status: 200,
  payload:   { 'type' => 'review',
               'ticker' => 'aapl',
               'order_action' => :buy,
               'quantity' => 10,
               'expiration' => :day,
               'price_label' => 'Market',
               'value_label' => 'Estimated Cost',
               'message' => 'You are about to place a market order to buy AAPL',
               'last_price' => 19.0,
               'bid_price' => 18.0,
               'ask_price' => 22.0,
               'timestamp' => 1455285085,
               'buying_power' => 1234.0,
               'estimated_commission' => 3.5,
               'estimated_value' => 25.0,
               'estimated_total' => 28.5,
               'warnings' => [],
               'must_acknowledge' => [],
               'amount' => 500,
               'token' => '140784ef96214a5186041abebdfe038a' },
  messages: [] }

```

Any messages in  `payload.warnings` must be displayed to the user.

any messages in `payload.must_acknowledge` must be shown to the user with check boxes that they must acknowledge

### Zerodha::Order::Place

Place an order previously reviewed by `Zerodha::Order::Preview`

Example Call

```
Zerodha::Order::Place.new(
  token: preview_token
).call.response
```

Example response

```
{ raw:   { 'broker' => 'your broker',
           'confirmationMessage' =>
    'Your order message 4049c988b1422d52217af9 to buy 10 shares of aapl at market price has been successfully transmitted to your broker at 12/02/16 1:19 PM EST.',
           'longMessages' => ['Transmitted succesfully to your broker'],
           'orderInfo' =>
    { 'universalOrderInfo' =>
      { 'action' => 'buy',
        'quantity' => '10',
        'symbol' => 'aapl',
        'price' => { 'type' => 'market' },
        'expiration' => 'day' },
      'action' => 'Buy',
      'quantity' => 10,
      'symbol' => 'aapl',
      'price' =>
      { 'type' => 'Market',
        'last' => 19.0,
        'bid' => 18.0,
        'ask' => 22.0,
        'timestamp' => '2016-02-12T18:19:20Z' },
      'expiration' => 'Good For The Day' },
           'orderNumber' => '4049c988b1422d52217af9',
           'shortMessage' => 'Order Successfully Submitted',
           'status' => 'SUCCESS',
           'timestamp' => '12/02/16 1:19 PM EST',
           'token' => 'dc2427db16d244e7967857cc140cf011' },
  status: 200,
  payload:   { 'type' => 'success',
               'ticker' => 'aapl',
               'order_action' => :buy,
               'quantity' => 10,
               'expiration' => :day,
               'price_label' => 'Market',
               'message' =>
    'Your order message 4049c988b1422d52217af9 to buy 10 shares of aapl at market price has been successfully transmitted to your broker at 12/02/16 1:19 PM EST.',
               'last_price' => 19.0,
               'bid_price' => 18.0,
               'ask_price' => 22.0,
               'price_timestamp' => 1_455_301_160,
               'timestamp' => 1_329_416_340,
               'order_number' => '4049c988b1422d52217af9',
               'token' => 'dc2427db16d244e7967857cc140cf011' },
  messages: ['Order Successfully Submitted'] }
```

Failed Call will raise a `Trading::Errors::OrderException` with similar attributes:

```
{:type=>:error,
 :code=>500,
 :broker_code=>600,
 :description=>"Could Not Complete Your Request",
 :messages=>["Your session has expired. Please try again"]}
```

## Zerodha::Order::Status

Get the status of all user orders or get the status of a single order

Example Call

```
Zerodha::Order::Place.new(
  token: preview_token,
  account_number,
  order_number
).call.response
```

Omit the `order_number` to get the status of all orders for the account

Example response
```
{:raw=>
  {"accountNumber"=>"brkAcct1",
   "longMessages"=>nil,
   "orderStatusDetailsList"=>
    [{"groupOrderId"=>nil,
      "groupOrderType"=>"null",
      "groupOrders"=>[],
      "orderExpiration"=>"DAY",
      "orderLegs"=>
       [{"action"=>"BUY",
         "filledQuantity"=>0,
         "fills"=>[],
         "orderedQuantity"=>5000,
         "priceInfo"=>
          {"bracketLimitPrice"=>0.0,
           "conditionFollowPrice"=>nil,
           "conditionPrice"=>0.0,
           "conditionSymbol"=>nil,
           "conditionType"=>nil,
           "initialStopPrice"=>0.0,
           "limitPrice"=>0.0,
           "stopPrice"=>0.0,
           "trailPrice"=>0.0,
           "triggerPrice"=>0.0,
           "type"=>"MARKET"},
         "symbol"=>"CMG"}],
      "orderNumber"=>"123",
      "orderStatus"=>"OPEN",
      "orderType"=>"EQ"},
     {"groupOrderId"=>nil,
      "groupOrderType"=>"null",
      "groupOrders"=>[],
      "orderExpiration"=>"GTC",
      "orderLegs"=>
       [{"action"=>"SELL_SHORT",
         "filledQuantity"=>6000,
         "fills"=>
          [{"price"=>123.45,
            "quantity"=>6000,
            "timestamp"=>"01/01/15 12:34 PM EST"}],
         "orderedQuantity"=>10000,
         "priceInfo"=>
          {"bracketLimitPrice"=>0.0,
           "conditionFollowPrice"=>nil,
           "conditionPrice"=>0.0,
           "conditionSymbol"=>nil,
           "conditionType"=>nil,
           "initialStopPrice"=>0.0,
           "limitPrice"=>67.89,
           "stopPrice"=>123.45,
           "trailPrice"=>0.0,
           "triggerPrice"=>0.0,
           "type"=>"STOP_LIMIT"},
         "symbol"=>"MCD"}],
      "orderNumber"=>"456",
      "orderStatus"=>"PART_FILLED",
      "orderType"=>"EQ"}],
   "shortMessage"=>"Order statuses successfully fetched",
   "status"=>"SUCCESS",
   "token"=>"bba1c52b409245afb86919b9c3d7b898"},
 :status=>200,
 :payload=>
 {"type"=>"success",
  "orders"=>
   [{"ticker"=>"cmg",
     "order_action"=>:buy,
     "filled_quantity"=>0,
     "filled_price"=>0.0,
     "order_number"=>"123",
     "quantity"=>5000,
     "expiration"=>:day,
     "status"=>:open},
    {"ticker"=>"mcd",
     "order_action"=>:sell_short,
     "filled_quantity"=>6000,
     "filled_price"=>123.45,
     "order_number"=>"456",
     "quantity"=>10000,
     "expiration"=>:gtc,
     "status"=>:part_filled}],
  "token"=>"3384aeb24c2143f5b78ee3e1311a40eb"}
```
## Zerodha::Order::Cancel

Cancel an unfulfilled order.  The payload is identical to `Zerodha::Order::Status` in that it return the order status of the cancelled order

Example Call

```
Zerodha::Order::Cancel.new(
  token: preview_token,
  account_number,
  order_number
).call.response
```


Example response
```
{:raw=>
  {"accountNumber"=>"brkAcct1",
   "longMessages"=>nil,
   "orderStatusDetailsList"=>
    [{"groupOrderId"=>nil,
      "groupOrderType"=>"null",
      "groupOrders"=>[],
      "orderExpiration"=>"GTC",
      "orderLegs"=>
       [{"action"=>"BUY",
         "filledQuantity"=>0,
         "fills"=>[],
         "orderedQuantity"=>275000,
         "priceInfo"=>
          {"bracketLimitPrice"=>0.0,
           "conditionFollowPrice"=>nil,
           "conditionPrice"=>0.0,
           "conditionSymbol"=>nil,
           "conditionType"=>nil,
           "initialStopPrice"=>0.0,
           "limitPrice"=>0.0,
           "stopPrice"=>0.0,
           "trailPrice"=>0.0,
           "triggerPrice"=>0.0,
           "type"=>"MARKET"},
         "symbol"=>"FTFY"}],
      "orderNumber"=>"456",
      "orderStatus"=>"PENDING_CANCEL",
      "orderType"=>"EQ"}],
   "shortMessage"=>"Order statuses successfully fetched",
   "status"=>"SUCCESS",
   "token"=>"d9c45bb6223f425c865ed7c88042ad1f"},
 :status=>200,
 :payload=>
  {"type"=>"success",
   "orders"=>
    [{"ticker"=>"ftfy",
      "order_action"=>:buy,
      "filled_quantity"=>0,
      "filled_price"=>0.0,
      "order_number"=>"456",
      "quantity"=>275000,
      "expiration"=>:gtc,
      "status"=>:pending_cancel}],
   "token"=>"d9c45bb6223f425c865ed7c88042ad1f"},
 :messages=>["Order statuses successfully fetched"]}



```


### Zerodha::Instrument::Details

Example Call

```
Zerodha::Order::Cancel.new(
  token: preview_token,
  ticker: "aapl"
).call.response
```

Example response

```
{:raw=>
  {{"instrumentID"=>"a67422af-8504-43df-9e63-7361eb0bd99e",
    "name"=>"Apple, Inc.",
    "category"=>"Stock",
    "currencyID"=>"USD",
    "description"=>"Apple Inc. designs, manufactures, and markets mobile communication and media devices, personal computers, and portable digital music players worldwide.",
    "exchangeID"=>"XNAS",
    "limitStatus"=>0,
    "instrumentTypeID"=>6,
    "isLongOnly"=>true,
    "marginCurrencyID"=>"USD",
    "orderSizeMax"=>10000,
    "orderSizeMin"=>0.0001,
    "orderSizeStep"=>0.0001,
    "rateAsk"=>97.45,
    "rateBid"=>97.44,
    "rateHigh"=>99.12,
    "rateLow"=>97.1,
    "rateOpen"=>98.69,
    "ratePrecision"=>2,
    "symbol"=>"AAPL",
    "tags"=>["aapl", "sp500", "usa"],
    "tradeStatus"=>1,
    "tradingHours"=>"Mon-Fri: 9:30am - 4:00pm ET",
    "uom"=>"shares",
    "urlImage"=>"http://syscdn.drivewealth.net/images/symbols/aapl.png",
    "urlInvestor"=>"http://investor.apple.com/",
    "chaikinPgr"=>
     "{  \"Corrected PGR Value\":\"2\",  \"Financial Metrics\":\"2\",  \"Earnings Performance\":\"4\",  \"Price/Volume Activity\":\"3\",  \"Expert Opinions\":\"1\",  \"pgrSummaryText\":\"The Chaikin Power Gauge Rating for AAPL is Bearish due to very negative expert activity and poor financial metrics. The stock also has strong earnings performance.\"}",
    "sector"=>"Technology",
    "priorClose"=>97.34,
    "close"=>0,
    "lastTrade"=>97.34,
    "nameLower"=>"apple, inc.",
    "underlyingID"=>"0",
    "marketState"=>2,
    "minTic"=>0,
    "pipMultiplier"=>1,
    "tickerSymbol"=>"AAPL",
    "rebateSpread"=>0,
    "longOnly"=>true}=>nil},
 :status=>200,
 :payload=>
  {"type"=>"success",
   "broker_id"=>"a67422af-8504-43df-9e63-7361eb0bd99e",
   "ticker"=>"aapl",
   "last_price"=>97.34,
   "bid_price"=>97.44,
   "ask_price"=>97.45,
   "order_size_max"=>10000.0,
   "order_size_min"=>0.0001,
   "order_size_step"=>0.0001,
   "allow_fractional_shares"=>true,
   "timestamp"=>1465915138,
   "warnings"=>[],
   "must_acknowledge"=>[],
   "token"=>"628f9e2b-6acb-4d6f-9fff-63c93d23d9d0.2016-06-14T14:38:53.603Z"},
 :messages=>["success"]}
```
