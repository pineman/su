require 'sinatra'
require 'json'

require_relative 'gen'

puts "mjit: #{RubyVM::MJIT.enabled?}"
puts "yjit: #{RubyVM::YJIT.enabled?}"

set :public_folder, 'html'

get '/' do
  redirect '/index.html'
end

get '/gen' do
  # easy - ]0, 100[
  # medium - [100, 300[
  # hard - [300, +inf[
  content_type :json
  diff = params['diff'].to_i
  gen(diff).to_json
end
