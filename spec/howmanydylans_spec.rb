require "helper"

describe HowManyDylans::API::V1 do
  include Rack::Test::Methods

  def app
    HowManyDylans::API::V1.new
  end

  describe "things" do
    describe "GET :thing" do
      describe "when existant" do
        before do
          @thing = HowManyDylans::Thing.create(:name => "thing", "dylans" => 2)
          get "/things/thing"
        end

        it "should return a 200" do
          last_response.status.must_equal 200
        end

        it "should return JSON" do
          last_response.body.must_equal @thing.to_json
        end
      end

      describe "when non-existant" do
        it "should return a 404" do
          get "/things/non-existant"
          last_response.status.must_equal 404
        end
      end
    end

    describe "GET similar/:thing" do
      describe "with similar things" do
        before do
          HowManyDylans::Thing.create(:name => "thing", :dylans => 2)
          @dylan = HowManyDylans::Thing.create(:name => "dylan", :dylans => 3)
          @dylan.values[:similarity] = 0.375
          @bob_dylan = HowManyDylans::Thing.create(:name => "bob_dylan", :dylans => 2)
          @bob_dylan.values[:similarity] = 0.25

          get "/things/similar/ylan"
        end

        it "should return a 200" do
          last_response.status.must_equal 200
        end

        it "should return similar things" do
          last_response.body.must_equal [@dylan, @bob_dylan].to_json
        end
      end

      describe "without similar things" do
        it "should return nothing" do
          get "/things/similar/non-existant"
          last_response.body.must_equal [].to_json
        end
      end

      describe "SQL injection" do
        it "should not fuck up" do
          HowManyDylans::Thing.create(:name => "thing", :dylans => 2)
          get URI.escape("/things/similar/'')); DELETE FROM things")

          HowManyDylans::Thing.count.must_equal 1
        end
      end
    end

    describe "POST" do
      before do
        header "Api-Token", "youhaventsetapasswordnincompoop"
      end

      describe "with a unique name and valid dylans" do
        before do
          post "/things", :thing => { :name => "thing", :dylans => 2 }
        end

        it "should return a 201" do
          last_response.status.must_equal 201
        end

        it "should return JSON" do
          last_response.body.must_equal HowManyDylans::Thing.first.to_json
        end
      end

      describe "with a non-unique name" do
        it "should return a 500" do
          HowManyDylans::Thing.create(:name => "thing", :dylans => 2)
          post "/things", :thing => { :name => "thing", :dylans => 2 }
          last_response.status.must_equal 500
        end
      end

      describe "with invalid dylans" do
        it "should return a 500" do
          post "/things", :thing => { :name => "thing", :dylans => -1 }
          last_response.status.must_equal 500

          post "/things", :thing => { :name => "thing", :dylans => 0 }
          last_response.status.must_equal 500

          post "/things", :thing => { :name => "thing", :dylans => 4 }
          last_response.status.must_equal 500
        end
      end
    end
  end
end
