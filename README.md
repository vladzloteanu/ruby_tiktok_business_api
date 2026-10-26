# TikTok Business API Ruby Gem

A Ruby interface to the TikTok Business API with support for campaigns, ad groups, ads, and more.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'tiktok_business_api'
```

And then execute:

```bash
$ bundle install
```

Or install it yourself as:

```bash
$ gem install tiktok_business_api
```

## Getting Started

### Configuration

You need to configure the client with your TikTok app credentials:

```ruby
TiktokBusinessApi.configure do |config|
  config.app_id = 'your_app_id'
  config.secret = 'your_app_secret'
  config.debug = true # Enable request/response logging
end
```

If you want to use a custom logger:

```ruby
require 'logger'
logger = Logger.new($stdout)
logger.level = Logger::DEBUG

TiktokBusinessApi.configure do |config|
  config.logger = logger
end
```

### Authentication

#### Generate an authorization URL

```ruby
client = TiktokBusinessApi.client
auth_url = client.auth.authorization_url('https://your-redirect-url.com/callback')
```

After the user authorizes your app, TikTok will redirect to your callback URL with an authorization code.

#### Generate an access token

```ruby
auth_code = 'auth_code_from_callback'
redirect_uri = 'https://your-redirect-url.com/callback'

response = client.auth.generate_access_token(auth_code, redirect_uri)
access_token = response['data']['access_token']
```

The access token will automatically be stored in your client configuration for future requests.

### Working with Campaigns

```ruby
# Create a new client instance
client = TiktokBusinessApi.client(access_token: 'your_access_token')

# Create a campaign
advertiser_id = '6000000000000'
campaign_params = {
  campaign_name: 'My First Campaign',
  objective_type: 'TRAFFIC',
  budget_mode: 'BUDGET_MODE_TOTAL',
  budget: 1000
}

campaign = client.campaigns.create(advertiser_id, campaign_params)
campaign_id = campaign['campaign_id']

# Get a list of campaigns
campaigns = client.campaigns.list(advertiser_id)

# Get a specific campaign
campaign = client.campaigns.get(advertiser_id, campaign_id)

# Update a campaign
update_params = {
  campaign_name: 'Updated Campaign Name'
}
client.campaigns.update(advertiser_id, campaign_id, update_params)

# Enable/disable a campaign
client.campaigns.update_status(advertiser_id, campaign_id, 'DISABLE')

# Delete a campaign
client.campaigns.delete(advertiser_id, campaign_id)

# List all campaigns with pagination (yields each campaign to a block)
client.campaigns.list_all(advertiser_id) do |campaign|
  puts "Campaign: #{campaign['campaign_name']}"
end
```

### Working with Identities

The Identity feature allows you to create Spark Ads by working with authorized TikTok accounts.

```ruby
# List available identities
identities = client.identities.list(advertiser_id: 'your_advertiser_id')

# Get information about a specific identity
identity_info = client.identities.get_info(
  advertiser_id: 'your_advertiser_id',
  identity_id: 'identity_id',
  identity_type: 'TT_USER'
)

# Create a custom user identity
new_identity = client.identities.create(
  advertiser_id: 'your_advertiser_id',
  display_name: 'My Custom Identity',
  image_uri: 'image_id_from_uploaded_image' # Optional
)

# List all identities with pagination
client.identities.list_all(advertiser_id: 'your_advertiser_id') do |identity|
  puts "Identity: #{identity['display_name']} (#{identity['identity_type']})"
end
```

### Working with Comments

Moderate the comments posted on your ads. TikTok has no comment webhook, so poll `list` per ad group.
Comments older than 90 days are not returned.

```ruby
# List the comments of an ad group (one page, or every page with list_all)
client.comments.list_all(
  advertiser_id: 'your_advertiser_id',
  search_field: 'ADGROUP_ID',
  search_value: 'adgroup_id',
  start_time: '2026-10-01',
  end_time: '2026-10-26'
) do |comment|
  puts "#{comment['user_name']}: #{comment['content']}"
end

# Hide / unhide comments
client.comments.hide(advertiser_id: 'your_advertiser_id', comment_ids: ['comment_id'])
client.comments.unhide(advertiser_id: 'your_advertiser_id', comment_ids: ['comment_id'])

# Reply to or delete a comment (needs the ad's id, post id and identity)
ad = {ad_id: 'ad_id', tiktok_item_id: 'item_id', identity_id: 'identity_id', identity_type: 'CUSTOMIZED_USER'}
client.comments.post(advertiser_id: 'your_advertiser_id', comment_id: 'comment_id', text: 'Thanks!', **ad)
client.comments.delete(advertiser_id: 'your_advertiser_id', comment_id: 'comment_id', **ad)
```

### Working with Blocked Words

Comments containing a blocked word are hidden by TikTok itself.

```ruby
words = client.blocked_words.list_all(advertiser_id: 'your_advertiser_id')
client.blocked_words.create(advertiser_id: 'your_advertiser_id', blocked_words: ['scam'])
client.blocked_words.update(advertiser_id: 'your_advertiser_id', old_word: 'scam', new_word: 'scams')
client.blocked_words.delete(advertiser_id: 'your_advertiser_id', blocked_words: ['scams'])
```

### Working with Images

Upload and manage images for your ads:

```ruby
# Upload an image file
uploaded_image = client.images.upload(
  advertiser_id: 'your_advertiser_id',
  image_file: File.open('/path/to/image.jpg')
)

# Get image info
image_info = client.images.get_info('your_advertiser_id', uploaded_image['image_id'])

# Search for images
images = client.images.search(
  advertiser_id: 'your_advertiser_id',
  page: 1,
  page_size: 20
)
```

## Logging Requests and Responses

You can enable debug logging to see all API requests and responses:

```ruby
TiktokBusinessApi.configure do |config|
  config.debug = true
  config.logger = Logger.new($stdout)
end
```

## Error Handling

The gem raises specific exceptions for different error types:

```ruby
begin
  client.campaigns.create(advertiser_id, campaign_params)
rescue TiktokBusinessApi::AuthenticationError => e
  puts "Authentication failed: #{e.message}"
rescue TiktokBusinessApi::RateLimitError => e
  puts "Rate limit exceeded: #{e.message}"
rescue TiktokBusinessApi::ApiError => e
  puts "API error: #{e.message}, Status code: #{e.status_code}, Body: #{e.body}"
rescue TiktokBusinessApi::Error => e
  puts "General error: #{e.message}"
end
```

## Development

### With Docker (recommended)

This gem includes a Docker-based development environment to ensure consistent development and testing.

#### Prerequisites

- Docker and Docker Compose
- Make (optional, but recommended)

#### Setup using Make

```bash
# Set up the development environment
make setup

# Run tests
make test

# Open a shell in the Docker container
make shell

# Start a console with the gem loaded
make console

# Run Standard linting
make lint

# Automatically fix linting issues
make lint-fix

# Generate documentation
make docs

# Build the gem
make build

# Prepare a new release
make release

# Publish to RubyGems
make publish

# View all available commands
make help
```

#### Without Make

If you prefer to use Docker Compose directly:

```bash
# Set up the development environment
docker-compose build

# Run tests
docker-compose run --rm test

# Start a console with the gem loaded
docker-compose run --rm console

# Open a shell in the Docker container
docker-compose run --rm gem bash
```

### Without Docker

If you prefer to develop without Docker:

```bash
# Install dependencies
bundle install

# Run tests
bundle exec rake spec

# Run linting
bundle exec standardrb

# Generate documentation
bundle exec yard

# Build the gem
bundle exec rake build

# Start a console with the gem loaded
bin/console
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
