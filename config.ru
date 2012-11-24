require File.dirname(__FILE__) + '/howmanydylans'

class ::Logger; alias_method :write, :<<; end
logger = ENV['RACK_ENV'] == 'test' ? Logger.new('log/test.log') : Logger.new(STDOUT)
use Rack::CommonLogger, logger

run HowManyDylans::API::V1
