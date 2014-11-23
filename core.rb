require 'sinatra'
require 'json'
require 'redis'

$redis = Redis.new
error = {status: 'error'}
status_ok = {:status => "ok"}

get '/' do
  content_type:json
  error[:msg] = "Please Don't access root"
  error.to_json
end

post '/1/api/push' do
  content_type:json
  data = JSON.parse(params['data'])


  begin
    unless data.has_key? "token"
      error[:msg] = 'Invalid Code'
      return error
    end
    # try adding the message to the redis list
    $redis.lpush "msgQ_#{data['name']}", data['msg']
  rescue
    error[:msg] = "error adding message"
    return error
  end
  return status_ok
end

get '/1/api/:name/pop' do
  content_type:json
  name = params['name']
  begin
    $redis.rpop "msgQ_#{name}"
  rescue
    error[:msg] = "user does not exist"
    return error
  end
end
