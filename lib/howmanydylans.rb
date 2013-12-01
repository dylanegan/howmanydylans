ENV["RACK_ENV"] ||= "development"
$stdout.sync = true

require "grape"
require "sequel"
require "sinatra/base"

DB = Sequel.connect ENV["DATABASE_URL"] || "postgres://localhost/howmanydylans_#{ENV["RACK_ENV"]}"

Sequel.extension :migration

Sequel::Migrator.run(DB, "migrations")

module HowManyDylans
  class Thing < Sequel::Model
    plugin :json_serializer
    plugin :validation_helpers

    def similarity
      @values[:similarity]
    end

    def validate
      validates_presence [:dylans, :name]
      validates_unique :name

      errors.add(:dylans, "must be positive") unless dylans > 0
      errors.add(:dylans, "must have a max of 3") if dylans > 3
    end
  end

  module API
    class V1 < Grape::API
      default_format :json
      format :json
      version "v1", :using => :header, :vendor => "howmanydylans"

      helpers do
        def authenticate!
          error!('Unauthorized', 401) unless headers['Api-Token'] == (ENV["HTTP_BASIC_PASSWORD"] || "youhaventsetapasswordnincompoop")
        end
      end

      resource :things do
        get ":thing" do
          if @thing = Thing.where(:name => params[:thing]).first
            @thing
          else
            status 404
          end
        end

        get "similar/:thing" do
          lower_unaccented_thing = DB["SELECT lower(unaccent_text(?))", params[:thing]].first[:lower]
          Thing.select(:id, :name, :dylans, Sequel.lit("similarity(name, ?)", params[:thing])).
               where("lower(unaccent_text(name)) ~~ ?", "%#{lower_unaccented_thing}%").
               order(Sequel.desc(Sequel.lit("similarity(name, ?)", params[:thing])))
        end

        post do
          authenticate!

          @thing = Thing.new(params[:thing])
          if @thing.save(:raise_on_failure => false)
            @thing
          else
            status 500
          end
        end
      end
    end
  end

  class Application < Sinatra::Base
    set :static, true
    set :root, File.dirname(__FILE__) + "/../"

    get "/" do
      erb :index
    end

    get "/things/:thing.png" do
      @thing = Thing.where(:name => params[:thing]).first
      if @thing
        params[:banner] ?
          redirect("/images/#{@thing.dylans}.dylans.banner.png") :
          redirect("/images/#{@thing.dylans}.dylans.png")
      else
        404
      end
    end

    get "/things/:thing" do
      @thing = Thing.where(:name => params[:thing]).first
      if @thing
        erb :thing
      else
        404
      end
    end
  end
end
