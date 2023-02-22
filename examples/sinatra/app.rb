# frozen_string_literal: true

require "sinatra"
require "sinatra/cookies"

CABLE_URL = ENV.fetch("CABLE_URL", "/cable")

class App < Sinatra::Application # :nodoc:
  set :public_folder, "assets"

  enable :sessions
  set :session_secret, "secret_key_with_size_of_32_bytes_dff054b19c2de43fc406f251376ad40"

  get "/" do
    if session[:user]
      slim :index
    else
      slim :login
    end
  end

  get "/sign_in" do
    slim :login
  end

  post "/sign_in" do
    if params["user"]
      session[:user] = params["user"]
      cookies["user"] = params["user"]
      redirect "/"
    else
      slim :login
    end
  end

  post "/rooms" do
    if params["id"]
      redirect "/rooms/#{params["id"]}"
    else
      slim :index
    end
  end

  get "/rooms/:id" do
    if session[:user]
      @room_id = params["id"]
      @user = session[:user]
      slim :room
    else
      slim :login
    end
  end
end
