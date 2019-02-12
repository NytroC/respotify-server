require 'sinatra'
require 'json'
require 'aws-sdk-s3'
require 'sinatra/cross_origin'

class Server < Sinatra::Base

    def initialize
        super()
        @role_credentials = Aws::AssumeRoleCredentials.new(
            client: Aws::STS::Client.new(),
            role_arn: "arn:aws:iam::170621239995:role/s3admin",
            role_session_name: "Ruby-CLI"
          )
        @s3 = Aws::S3::Client.new(credentials: @role_credentials, region: "us-east-1")
        @signer = Aws::S3::Presigner.new(client: @s3)
    end 
    configure do
        enable :cross_origin
    end
    before do
        response.headers['Access-Control-Allow-Origin'] = '*'
    end
      
      # routes...
    options "*" do
        response.headers["Allow"] = "GET, POST, OPTIONS"
        response.headers["Access-Control-Allow-Headers"] = "Authorization, Content-Type, Accept, X-User-Email, X-Auth-Token"
        response.headers["Access-Control-Allow-Origin"] = "*"
        200
    end
    get '/' do
        resp = @s3.list_objects({
            bucket: "do-not-kick", 
            max_keys: 100, 
        })
        resp_hash = resp.to_h
        artist_list = []
        resp_hash[:contents].each do |object|
            artist_object = object[:key].split('/')
            url = @signer.presigned_url(:get_object, 
                                        bucket: "do-not-kick", 
                                        key: object[:key],
                                        expires_in: 3600)
            puts url

            current_song = {
                artist: artist_object[0],
                album: artist_object[1],
                song: artist_object[2],
                url: url
            }
            artist_list << current_song
        end 
        artist_list.to_json
    end
end