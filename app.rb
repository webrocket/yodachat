require 'sinatra'

set :root, File.dirname(__FILE__)
set :views, File.join(settings.root, "views")
set :public_folder, File.join(settings.root, "public")

get '/' do
  erb :index
end

get '/:id' do
  erb :chat
end
