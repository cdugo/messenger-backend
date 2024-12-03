require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Messenger
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.2

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Add custom error classes to autoload paths
    config.autoload_paths += %W[#{config.root}/app/lib]
    config.eager_load_paths += %W[#{config.root}/app/lib]

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Only loads a smaller set of middleware suitable for API only apps.
    # Middleware like session, flash, cookies can be added back manually.
    # Skip views, helpers and assets when generating a new resource.
    config.api_only = true

    # Add session middleware
    config.middleware.use ActionDispatch::Cookies
    config.middleware.use ActionDispatch::Session::CookieStore,
      key: 'message_app_session',
      same_site: :none,
      secure: Rails.env.production?,
      http_only: false, # Allow JavaScript access
      domain: :all # Allow cross-domain cookies
      
    # Configure CORS and cookie settings
    config.action_dispatch.cookies_same_site_protection = :none
    config.action_dispatch.cookies_serializer = :json
    
    # Add CORS headers for all responses
    config.action_dispatch.default_headers = {
      'Access-Control-Allow-Credentials' => 'true'
    }
  end
end
