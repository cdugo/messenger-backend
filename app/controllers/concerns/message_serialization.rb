module MessageSerialization
  extend ActiveSupport::Concern
  include Rails.application.routes.url_helpers
  include UrlOptions

  private

  def message_includes
    { 
      include: { 
        user: { only: :username }, 
        reactions: { include: { user: { only: :username } } }
      },
      methods: [:attachment_urls]
    }
  end
end 