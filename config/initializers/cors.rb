# Be sure to restart your server when you modify this file.

# Read more: https://github.com/cyu/rack-cors

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    # Convert origins string to array and strip whitespace
    origins_list = ENV.fetch('CORS_ALLOWED_ORIGINS', 'http://localhost:3000')
                     .split(',')
                     .map(&:strip)
                     .map { |origin| origin.gsub(/\/$/, '') } # Remove trailing slashes
    
    origins do |source, env|
      if origins_list.include?(source)
        source # Return the matching origin
      end
    end

    resource "*",
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      credentials: true,
      max_age: 3600,
      expose: [
        'Set-Cookie',
        'Authorization'
      ]
  end
end
