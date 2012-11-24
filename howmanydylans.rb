require "grape"
require "sequel"

DB = Sequel.connect ENV['DATABASE_URL'] || "postgres://localhost/howmanydylans_#{ENV['RACK_ENV']}"

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
    end
  end

  module API
    class V1 < Grape::API
      default_format :json
      format :json
      version 'v1', :using => :header, :vendor => 'howmanydylans'

      resource :things do
        get ':thing' do
          if @thing = Thing.where(:name => params[:thing]).first
            @thing
          else
            status 404
          end
        end

        get 'similar/:thing' do
          lower_unaccented_thing = DB["SELECT lower(unaccent_text('#{params[:thing]}'))"].first[:lower]
          Thing.select(:id, :name, :dylans, Sequel.lit("similarity(name, '#{params[:thing]}')"))
               .where("lower(unaccent_text(name)) ~~ ?", "%#{lower_unaccented_thing}%")
               .order(Sequel.desc(Sequel.lit("similarity(name, '#{params[:thing]}')"))) 
        end

        post do
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
end
