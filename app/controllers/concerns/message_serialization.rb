module MessageSerialization
  extend ActiveSupport::Concern

  private

  def message_includes
    { include: { user: { only: :username }, reactions: { include: { user: { only: :username } } } } }
  end
end 