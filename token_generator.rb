require "faraday"
require "base64"
require "json"

require_relative "code_receiver"

class TokenGenerator
  ACCOUNT_BASE_URL = "https://accounts.spotify.com"
  PORT = 8888
  REDIRECT_URI = "http://localhost:#{PORT}/callback"

  def initialize(client_id:, client_secret:, refresh_token: nil)
    @client_id = client_id
    @authorization = Base64.strict_encode64("#{client_id}:#{client_secret}")
    @refresh_token = refresh_token
  end

  def generate
    if @refresh_token.nil?
      get_code
      get_refresh_token
    end

    get_access_token

    puts "Refresh Token:"
    puts @refresh_token

    puts

    puts "Access Token:"
    puts @access_token
  end

  private

  def get_code
    connection = Faraday.new(url: ACCOUNT_BASE_URL)

    scopes = %w(
      user-read-playback-state
      user-modify-playback-state
      user-read-currently-playing
      app-remote-control
      streaming
      playlist-read-private
      playlist-read-collaborative
      playlist-modify-private
      playlist-modify-public
    ).join(" ")

    response = connection.get(
      "/authorize",
      {
        response_type: "code",
        client_id: @client_id,
        scope: scopes,
        redirect_uri: REDIRECT_URI,
      },
    )

    redirect = response.headers["location"]

    receiver = CodeReceiver.new(port: PORT)
    receiver.listen

    puts "Open this URL: #{redirect}"

    @code = receiver.code
    puts
  end

  def get_refresh_token
    headers = {
      "Authorization" => "Basic #{@authorization}",
      "Content-Type" => "application/x-www-form-urlencoded",
    }
    
    params = {
      grant_type: "authorization_code",
      code: @code,
      redirect_uri: REDIRECT_URI,
    }

    connection = Faraday.new(
      url: ACCOUNT_BASE_URL,
      params: params,
      headers: headers
    )

    response = connection.post("/api/token") do |req|
      req.params = params
    end

    @refresh_token = JSON.parse(response.body)["refresh_token"]
  end

  def get_access_token
    headers = {
      "Authorization" => "Basic #{@authorization}",
      "Content-Type" => "application/x-www-form-urlencoded",
    }

    params = {
      grant_type: "refresh_token",
      refresh_token: @refresh_token,
    }

    connection = Faraday.new(
      url: ACCOUNT_BASE_URL,
      params: params,
      headers: headers
    )

    response = connection.post("/api/token") do |req|
      req.params = params
    end

    @access_token = JSON.parse(response.body)["access_token"]
  end
end


