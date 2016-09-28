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

A failure will raise a `Trading::Errors::LoginException` with the similar attributes:
```
{ type: :error,
  code: 500,
  description: 'Could Not Complete Your Request',
  messages: ['Your session has expired. Please try again'] }
```

### Zerodha::User::Account

Get the current financial state of an account.

Zerodha does not have accounts for users, this Gem synthesises an account whose name is the same as the user id, therefore the `account_number` parameter is ignored.

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
  {"ABHICAP"=>
    {"costBasis"=>0.0,
     "unrealizedPL"=>-100.0,
     "unrealizedDayPL"=>0.0,
     "mktPrice"=>93.75,
     "openQty"=>0.0,
     "priorClose"=>0.0},
   "AXISBANK"=>
    {"costBasis"=>475.0,
     "unrealizedPL"=>-42.5,
     "unrealizedDayPL"=>-432.55,
     "mktPrice"=>432.55,
     "openQty"=>1.0,
     "priorClose"=>0.0},
   "NIFTY15DEC9500CE"=>
    {"costBasis"=>-347.5,
     "unrealizedPL"=>272.5,
     "unrealizedDayPL"=>0.0,
     "mktPrice"=>0.75,
     "openQty"=>-100.0,
     "priorClose"=>0.75}},
 :status=>200,
 :payload=>
  {"type"=>"success",
   "cash"=>-1070.95,
   "power"=>-1070.95,
   "day_return"=>-432.55,
   "day_return_percent"=>-0.5475,
   "total_return"=>130.0,
   "total_return_percent"=>1.0196,
   "value"=>357.55,
   "token"=>"iv8j3e4y59dsr6rlkk5vkfkl86bsszsg"},
 :messages=>["success"]}
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
{ raw: {},
  status: 200,
  payload: { type: 'success', token: '765b7e4056334a27a9b65033b889878e', accounts: [] },
  messages: [] }
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

As Zerodha does not have the concept of multiple accounts, the account_number parameter is ignored.

Example Call

```
Zerodha::Positions::Get.new(
  token: token,
  account_number: account_number
).call.response
```

Successful response:

```
{:raw=>
  {"ABHICAP"=>
    {"costBasis"=>0.0,
     "unrealizedPL"=>-100.0,
     "unrealizedDayPL"=>0.0,
     "mktPrice"=>93.75,
     "openQty"=>0.0,
     "priorClose"=>0.0},
   "AXISBANK"=>
    {"costBasis"=>475.0,
     "unrealizedPL"=>-42.5,
     "unrealizedDayPL"=>-432.55,
     "mktPrice"=>432.55,
     "openQty"=>1.0,
     "priorClose"=>0.0},
   "NIFTY15DEC9500CE"=>
    {"costBasis"=>-347.5,
     "unrealizedPL"=>272.5,
     "unrealizedDayPL"=>0.0,
     "mktPrice"=>0.75,
     "openQty"=>-100.0,
     "priorClose"=>0.75}},
 :status=>200,
 :payload=>
  {"positions"=>
    [{"quantity"=>0.0,
      "cost_basis"=>0.0,
      "ticker"=>"abhicap",
      "instrument_class"=>"equity_or_etf",
      "change"=>-100.0,
      "holding"=>"long"},
     {"quantity"=>1.0,
      "cost_basis"=>475.0,
      "ticker"=>"axisbank",
      "instrument_class"=>"equity_or_etf",
      "change"=>-42.5,
      "holding"=>"long"},
     {"quantity"=>-100.0,
      "cost_basis"=>-347.5,
      "ticker"=>"nifty15dec9500ce",
      "instrument_class"=>"equity_or_etf",
      "change"=>272.5,
      "holding"=>"short"}],
   "pages"=>1,
   "page"=>0,
   "token"=>"9iz2t6te04zcbtg8xeivir1qtfmeqxip"},
 :messages=>["success"]}
```

Failed Call will raise a `Trading::Errors::PositionException` with similar attributes:

```
{ type: :error,
  code: 500,
  description: 'Could Not Fetch Your Positions',
  messages:   ['The account foooooobaaarrrr is not valid or not active anymore.'] }
```

### Zerodha::Order::Preview

This action is not supported by Zerodha and will raise an error.

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


### Zerodha::Order::Place

This action is not supported by Zerodha and will raise an error.

Example Call

```
Zerodha::Order::Place.new(
  token: preview_token
).call.response
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
  {"status"=>"success",
   "data"=>
    [{"order_id"=>"151220000000000",
      "parent_order_id"=>"151210000000000",
      "exchange_order_id"=>nil,
      "placed_by"=>"AB0012",
      "variety"=>"regular",
      "status"=>"COMPLETE",
      "tradingsymbol"=>"ACC",
      "exchange"=>"NSE",
      "instrument_token"=>22,
      "transaction_type"=>"BUY",
      "order_type"=>"MARKET",
      "product"=>"NRML",
      "validity"=>"DAY",
      "price"=>0.1,
      "quantity"=>75,
      "trigger_price"=>0.0,
      "average_price"=>0.1,
      "pending_quantity"=>0,
      "filled_quantity"=>10,
      "disclosed_quantity"=>0,
      "market_protection"=>0,
      "order_timestamp"=>"2015-12-20 15:01:43",
      "exchange_timestamp"=>nil,
      "status_message"=>"RMS:Margin Exceeds, Required:0, Available:0"},
     {"order_id"=>"151220000000099",
      "parent_order_id"=>"151210000000000",
      "exchange_order_id"=>nil,
      "placed_by"=>"AB0012",
      "variety"=>"regular",
      "status"=>"COMPLETE",
      "tradingsymbol"=>"ACC",
      "exchange"=>"NSE",
      "instrument_token"=>22,
      "transaction_type"=>"BUY",
      "order_type"=>"MARKET",
      "product"=>"NRML",
      "validity"=>"DAY",
      "price"=>0.99,
      "quantity"=>75,
      "trigger_price"=>0.0,
      "average_price"=>0.99,
      "pending_quantity"=>0,
      "filled_quantity"=>10,
      "disclosed_quantity"=>0,
      "market_protection"=>0,
      "order_timestamp"=>"2015-12-20 15:01:43",
      "exchange_timestamp"=>nil,
      "status_message"=>"RMS:Margin Exceeds, Required:0, Available:0"}]},
 :status=>200,
 :payload=>
  {"type"=>"success",
   "orders"=>
    [{"ticker"=>"acc",
      "order_action"=>:buy,
      "filled_quantity"=>10.0,
      "filled_price"=>0.1,
      "filled_total"=>1.0,
      "order_number"=>"151220000000000",
      "quantity"=>75.0,
      "expiration"=>:day,
      "status"=>:filled},
     {"ticker"=>"acc",
      "order_action"=>:buy,
      "filled_quantity"=>10.0,
      "filled_price"=>0.99,
      "filled_total"=>9.9,
      "order_number"=>"151220000000099",
      "quantity"=>75.0,
      "expiration"=>:day,
      "status"=>:filled}],
   "token"=>"9iz2t6te04zcbtg8xeivir1qtfmeqxip"},
 :messages=>["success"]}
```
## Zerodha::Order::Cancel

This action is not supported by Zerodha and will raise an error.

Example Call

```
Zerodha::Order::Cancel.new(
  token: preview_token,
  account_number,
  order_number
).call.response
```



### Zerodha::Instrument::Details

Get pricing and fraction share details for this ticker

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
  {"status"=>"success",
   "data"=>
    {"last_price"=>1038.6,
     "volume"=>179858,
     "sell_quantity"=>0,
     "open_interest"=>0.0,
     "last_quantity"=>1,
     "change"=>-0.17,
     "ohlc"=>{"high"=>1041.8, "close"=>1040.45, "open"=>1040.0, "low"=>1034.0},
     "last_time"=>"2016-09-28 15:49:40",
     "change_percent"=>-1.85,
     "depth"=>
      {"sell"=>
        [{"price"=>0.0, "orders"=>0, "quantity"=>0},
         {"price"=>0.0, "orders"=>0, "quantity"=>0},
         {"price"=>0.0, "orders"=>0, "quantity"=>0},
         {"price"=>0.0, "orders"=>0, "quantity"=>0},
         {"price"=>0.0, "orders"=>0, "quantity"=>0}],
       "buy"=>
        [{"price"=>0.0, "orders"=>0, "quantity"=>0},
         {"price"=>0.0, "orders"=>0, "quantity"=>0},
         {"price"=>0.0, "orders"=>0, "quantity"=>0},
         {"price"=>0.0, "orders"=>0, "quantity"=>0},
         {"price"=>0.0, "orders"=>0, "quantity"=>0}]},
     "buy_quantity"=>0}},
 :status=>200,
 :payload=>
  {"type"=>"success",
   "broker_id"=>"infy",
   "ticker"=>"infy",
   "last_price"=>1038.6,
   "bid_price"=>0.0,
   "ask_price"=>0.0,
   "order_size_max"=>99999.0,
   "order_size_min"=>1.0,
   "order_size_step"=>1.0,
   "allow_fractional_shares"=>false,
   "timestamp"=>1475068914,
   "warnings"=>[],
   "must_acknowledge"=>[],
   "token"=>"jn5vzx0clv0lt0s9y8h1k92s9uloqf9d"},
 :messages=>["success"]}
```
