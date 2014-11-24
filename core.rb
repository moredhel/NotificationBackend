require 'sinatra'
require 'json'
require 'redis'
require 'yo-ruby'

Yo.api_key = 'cd53977e-64cd-4249-92ba-fd22d7356b48'

$redis = Redis.new
status_ok = {:status => "ok"}

def json(msg)
  {msg: msg}.to_json
end

get '/' do
  content_type :json
  error 403, json('Please do not access root')
end

post '/1/api/push' do
  content_type :json
  data = JSON.parse(params['data'])

  begin
    if data.has_key? "token"
      # Try adding the message to the redis list
      $redis.lpush "msgQ_#{data['name']}", data['msg']
      Yo.yo! data['name']
    else
      error 500, json('Invalid code')
    end
  rescue
    error 500, json('Could not add message')
  end

  return status_ok
end

get '/1/api/:name/pop' do
  content_type :json
  name = params['name']

  if $redis.exists("msgQ_#{name}")
    $redis.rpop "msgQ_#{name}"
  else
    error 500, json('User does not exist')
  end
end
