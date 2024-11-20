module MessageSerialization
  extend ActiveSupport::Concern
  include Rails.application.routes.url_helpers

  private

  def message_includes
    host_options = { host: 'localhost:8080' }

    { 
      include: { 
        user: { only: :username }, 
        reactions: { include: { user: { only: :username } } }
      },
      methods: [:attachment_urls]
    }
  end
end 