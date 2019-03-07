require 'sinatra'
require 'json'
require 'aws-sdk'
require 'sinatra/cross_origin'

class Server < Sinatra::Base

    def initialize
        super()
        @role_credentials = Aws::AssumeRoleCredentials.new(
            client: Aws::STS::Client.new(),
            role_arn: "arn:aws:iam::170621239995:role/s3admin",
            role_session_name: "Ruby-CLI"
        )
        @dynamodb = Aws::DynamoDB::Client.new(
            credentials: @role_credentials,
            region: "us-east-1"
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
                                        expires_in: 3600
            )
            
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
    get '/genres' do
        # get genres
        params = {
            table_name: "music",
            projection_expression: "genre"
        }
        begin
            resp = @dynamodb.scan(params)
            resp[:items].uniq.to_json
        rescue
            "error in request"
        end
    end

    get '/artist/by/genre' do
        genre = params[:genre]
        #artist for genre
        params2 = {
            table_name: "music",
            projection_expression: "artist",
            key_condition_expression: "genre = :genre",
            expression_attribute_values: {
                ":genre" => genre
            }
        }
        begin
            resp2 = @dynamodb.query(params2)
            resp2[:items].uniq.to_json
        rescue
            "error in request"
        end
    end

    get '/albums/for/artist' do
        artist = params[:artist]
        #albums for artist
        params4 = {
            table_name: "music",
            index_name: "artist_gsi",
            projection_expression: "album",
            key_condition_expression: "artist = :artist",
            expression_attribute_values: {
            ":artist" => artist
            }
        }
        begin
            resp4 = @dynamodb.query(params4)
            resp4[:items].uniq.to_json
        rescue
            "error in request"
        end
    end 

    get '/songs/for/album' do
        album = params[:album]
        #songs for album
        params5 = {
            table_name: "music",
            index_name: "album_song",
            projection_expression: "song",
            key_condition_expression: "album = :album",
            expression_attribute_values: {
            ":album" => album
            }
        }
        begin
            resp5 = @dynamodb.query(params5)
            resp5[:items].uniq.to_json
        rescue
            "error in request"
        end
    end 

    get '/song' do
        song = params[:song]
        url = ''
        params3 = {
            table_name: "music",
            projection_expression: "song, s3_location",
            filter_expression: "song = :song",
            expression_attribute_values: {
                ":song" => song,
            }
        }
        begin
            resp3 = @dynamodb.scan(params3)
            unless resp3[:items][0]["s3_location"].nil?
                url = @signer.presigned_url(:get_object, 
                    bucket: "do-not-kick", 
                    key: object[:key],
                    expires_in: 3600
                )
            end 
            resp3[:items][0]["song"]

            return {
                song: resp3[:items][0]["song"],
                url: url
            }.to_json
        rescue
            "error in request"
        end
    end

    post "/save-user" do
        params = JSON.parse(request.body.read).to_h
        user_name = params["userName"]
        user_id = params["userId"]
        email = params["userEmail"]
        @dynamodb.put_item({
            table_name: "user", # required
            item: { # required
              "name" => user_name,
              "id" => user_id,
              "email" => email,
            }
          })
        return "status: 200, ok"
    end 
end