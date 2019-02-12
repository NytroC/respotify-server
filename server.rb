require 'sinatra'
require 'json'
require 'aws-sdk-s3'

class Server < Sinatra::Base
    set :port, 3000
    def initialize
        super()
        @role_credentials = Aws::AssumeRoleCredentials.new(
            client: Aws::STS::Client.new(),
            role_arn: "arn:aws:iam::170621239995:role/s3admin",
            role_session_name: "Ruby-CLI"
          )
        @s3 = Aws::S3::Client.new(credentials: @role_credentials)
        @signer = Aws::S3::Presigner.new
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