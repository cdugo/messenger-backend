ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    # Specify the order to ensure foreign key constraints are satisfied
    set_fixture_class server_read_states: ServerReadState
    fixtures :users, :servers, :server_members, :messages, :server_read_states

    # Add more helper methods to be used by all tests here...
    def sign_in_as(user)
      post "/login", params: { username: user.username, password: "password123" }
      @current_user = user
    end

    def current_user
      @current_user
    end

    def json_response
      JSON.parse(response.body)
    end

    def hash_including(hash)
      HashIncludingMatcher.new(hash)
    end
  end
end

class HashIncludingMatcher
  attr_reader :expected

  def initialize(expected)
    @expected = expected
  end

  def ==(actual)
    return false unless actual.is_a?(Hash)
    expected.all? do |key, value|
      actual.has_key?(key) && 
        (value.is_a?(HashIncludingMatcher) ? value == actual[key] : value === actual[key])
    end
  end

  def inspect
    "hash_including(#{expected.inspect})"
  end
end
