# Whop Messenger API

A real-time messaging API built with Ruby on Rails.

## Requirements

- Ruby 3.x
- PostgreSQL 13+
- Redis 6+
- AWS S3 account for file storage

## Development Setup

1. Install dependencies:

```bash
bundle install
```

2. Setup database:

```bash
rails db:create db:migrate
```

3. Start the server:

```bash
rails s
```

## Deployment Instructions

1. Set up environment variables:

   - Copy `.env.sample` to `.env`
   - Fill in all required environment variables

2. Configure your production database:

   - Ensure PostgreSQL is properly configured
   - Set `MESSENGER_DATABASE_PASSWORD` in your environment

3. Configure Redis:

   - Set up Redis server
   - Set `REDIS_URL` in your environment

4. Configure AWS S3:

   - Create an S3 bucket
   - Set up IAM user with appropriate permissions
   - Configure AWS environment variables

5. Configure Action Cable:

   - Set up your WebSocket server
   - Configure `ACTION_CABLE_URL` and `ALLOWED_ORIGINS`

6. Deploy using your preferred hosting service (Heroku, AWS, etc.)

## Security Notes

- Never commit `.env` file to version control
- Keep `master.key` secure and never share it
- Use SSL in production
- Configure CORS appropriately for your frontend domain

## API Documentation

[Add API documentation here]
