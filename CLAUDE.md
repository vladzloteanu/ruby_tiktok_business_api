# TikTok Business API Ruby Client

Ruby gem providing a client library for the TikTok Business API (Ads API). Enables programmatic management of campaigns, ad groups, ads, creative assets, identities, and reporting.

## Quick Commands

```bash
make test        # Run RSpec tests with coverage
make lint        # Check code style (StandardRB)
make lint-fix    # Auto-fix style issues
make console     # Interactive Ruby console
make docs        # Generate YARD documentation
```

## Architecture

```
lib/tiktok_business_api/
├── tiktok_business_api.rb    # Entry point, exposes configure/client
├── client.rb                 # HTTP client with Faraday, resource accessors
├── config.rb                 # Configuration (app_id, secret, access_token, etc.)
├── auth.rb                   # OAuth 2.0 flows
├── errors.rb                 # Error hierarchy (AuthenticationError, RateLimitError, etc.)
├── utils.rb                  # MD5 calculation, content type detection
└── resources/
    ├── base_resource.rb      # HTTP helpers, pagination, path construction
    ├── crud_resource.rb      # Standard CRUD operations
    ├── campaign.rb           # Campaign management
    ├── adgroup.rb            # Ad group management + audience estimation
    ├── ad.rb                 # Ad management + ACO support
    ├── image.rb              # Image uploads (file/URL/file_id)
    ├── video.rb              # Video uploads with Smart Fix
    ├── identity.rb           # Identity/account management
    ├── account.rb            # Advertiser info
    ├── spc.rb                # Smart+ Campaigns
    └── reporting.rb          # Sync reports
```

## Key Patterns

### Resource Naming
- `RESOURCE_NAME` constant defines API resource name
- Override `resource_name` method for custom paths (e.g., `file/image/ad`)
- Base path: `#{api_version}/#{resource_name}`

### Parameter Conventions
- First param typically `advertiser_id` (owner)
- Keyword arguments preferred: `advertiser_id:`, `filtering:`
- Filtering serialized as JSON

### Pagination
- `list_all` provides automatic pagination with block support
- Returns array if no block given
- Uses `page_info.has_more` flag

### File Uploads
- Use `Faraday::Multipart::FilePart`
- MD5 auto-calculated via `Utils.calculate_md5()`
- Upload types: `UPLOAD_BY_FILE`, `UPLOAD_BY_URL`, `UPLOAD_BY_FILE_ID`

### Error Handling
- HTTP status mapped to specific error classes
- TikTok API: `code != 0` indicates error
- ErrorFactory creates appropriate error types

## Code Style

- All files use `# frozen_string_literal: true`
- StandardRB for linting (run `make lint-fix`)
- YARD documentation supported

## Testing

- RSpec with WebMock for HTTP mocking
- Fixtures in `spec/fixtures/`
- SimpleCov for coverage
- Helper: `fixture()`, `json_fixture()`

## Dependencies

- `faraday ~> 2.0` - HTTP client
- `faraday-retry`, `faraday-follow_redirects`, `faraday-multipart` - Middleware
- Ruby >= 2.6.0
