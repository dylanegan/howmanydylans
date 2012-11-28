require "minitest/autorun"
require 'rack/test'
require "simplecov" unless ENV['NO_SIMPLECOV']

ENV["RACK_ENV"] = 'test'

require 'howmanydylans'

require 'sinatra'

set :environment, :test

require 'database_cleaner'
DatabaseCleaner.strategy = :transaction
class MiniTest::Spec
  before :each do
    DatabaseCleaner.start
  end

  after :each do
    DatabaseCleaner.clean
  end
end
