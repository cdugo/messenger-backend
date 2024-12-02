# This file is copied to spec/ when you run 'rails generate rspec:install'
require 'spec_helper'
ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
# Prevent database truncation if the environment is production
abort("The Rails environment is running in production mode!") if Rails.env.production?
require 'rspec/rails'
# Add additional requires below this line. Rails is not loaded until this point!

Dir[Rails.root.join('spec', 'support', '**', '*.rb')].sort.each { |f| require f }

begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end

RSpec.configure do |config|
  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = Rails.root.join('test/fixtures')
  config.use_transactional_fixtures = true

  # Include Factory Bot syntax methods
  config.include FactoryBot::Syntax::Methods

  # Include our custom helpers
  config.include JsonHelper, type: :request

  # Authentication helper methods
  def sign_in(user)
    post "/login", params: { username: user.username, password: "password123" }
  end

  def sign_in_as(user)
    post "/login", params: { username: user.username, password: "password123" }
  end

  # Fixtures configuration
  config.fixture_path = "#{::Rails.root}/test/fixtures"
  config.use_transactional_fixtures = true
  
  # Load fixtures for every test
  config.before(:each) do
    ActiveRecord::FixtureSet.reset_cache
    fixtures_dir = "#{::Rails.root}/test/fixtures"
    fixtures = Dir["#{fixtures_dir}/**/*.yml"].map {|f| File.basename(f, '.yml') }
    ActiveRecord::FixtureSet.create_fixtures(fixtures_dir, fixtures)
  end

  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!
end

# Configure Shoulda Matchers
Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end
