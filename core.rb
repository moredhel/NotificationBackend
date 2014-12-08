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

post '/1/api/push', :provides => :json do
  content_type :json
  data = JSON.parse(request.body.read)
  puts data.keys

  begin
    if data.has_key? "token"
      # Try adding the message to the redis list
      $redis.lpush "msgQ_#{data['name']}", {
        :msg => data['msg'],
        :nick => data['nick']
      }
    else
      error 500, json('Invalid code')
    end
  rescue
    error 500, json('Could not add message')
  end

  return status_ok
end

get '/1/:name/pop' do
  content_type :json
  name = params['name']

  if $redis.exists("msgQ_#{name}")
    $redis.rpop "msgQ_#{name}"
  else
    error 500, json('User does not exist')
  end
end

get '/1/:name/pop/:num' do
  content_type :json
  name = params['name']
  num = params['num'].to_i.abs # abs, to stop people being id10ts

  if $redis.exists("msgQ_#{name}")
    data = []
    num.times {|x| data.push $redis.rpop "msgQ_#{name}"}
    {
      :data => data
    }.to_json
  else
    error 500, json('User does not exist')
  end
end

get '/1/:name/view/:num' do
  name = params['name']
  num = params['num'].to_i

  if $redis.exists("msgQ_#{name}")
    a = $redis.lrange "msgQ_#{name}", -1 * num, -1
    puts a[0]
    r = {
      :data => a
    }
    r.to_json
  else
    error 500, json('user does not exist')
  end
end
