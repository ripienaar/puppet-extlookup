dir = File.expand_path(File.dirname(__FILE__))
$LOAD_PATH.unshift("#{dir}/")
$LOAD_PATH.unshift("#{dir}/../lib")

require 'rubygems'

gem 'mocha'

require 'rspec'
require 'puppet'
require 'puppet/util/extlookup'
require 'rspec/mocks'
require 'mocha'

RSpec.configure do |config|
    config.mock_with :mocha
end
