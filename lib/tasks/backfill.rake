namespace :backfill do
  desc "Create read states for existing server members"
  task create_read_states: :environment do
    Server.find_each do |server|
      server.users.find_each do |user|
        next if ServerReadState.exists?(server: server, user: user)
        
        ServerReadState.create!(
          server: server,
          user: user,
          last_read_at: Time.current,
          unread_count: server.messages.where('created_at > ?', user.created_at).count
        )
      end
    end
  end
end 