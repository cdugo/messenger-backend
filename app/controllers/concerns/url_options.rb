module UrlOptions
  extend ActiveSupport::Concern
  
  def default_url_options
    {
      host: ENV.fetch('HOST', 'localhost:8080'),
      protocol: Rails.env.production? ? 'https' : 'http'
    }
  end
end 