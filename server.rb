require 'sinatra'
require 'json'

require_relative 'gen'

set :public_folder, 'html'

get '/' do
  redirect '/index.html'
end

get '/gen' do
  content_type :json
  diff = params['diff'].to_i
  gen(diff).to_json
end
