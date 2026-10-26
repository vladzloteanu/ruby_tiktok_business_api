require_relative "lib/tiktok_business_api/version"

Gem::Specification.new do |spec|
  spec.name = "tiktok_business_api"
  spec.version = TiktokBusinessApi::VERSION
  spec.authors = ["Vlad Zloteanu"]
  spec.email = ["vlad.zloteanu@gmail.com"]
  spec.summary = "Ruby client for the TikTok Business API / Tiktok Ads API"
  spec.description = "A Ruby interface to the TikTok Business API (Tiktok Ads API) with support for campaigns, ad groups, ads, and more"
  spec.homepage = "https://github.com/vladzloteanu/tiktok_business_api"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.6.0"

  spec.files = Dir.glob("{lib}/**/*") + %w[LICENSE.txt README.md]
  spec.require_paths = ["lib"]

  spec.add_dependency "faraday", "~> 2.0"
  spec.add_dependency "faraday-retry", "~> 2.0"
  spec.add_dependency "faraday-follow_redirects", "~> 0.3"
  spec.add_dependency "faraday-multipart", "~> 1.0"

  spec.add_development_dependency "bundler", ">= 2.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.10"
  spec.add_development_dependency "webmock", "~> 3.14"
  spec.add_development_dependency "simplecov", "~> 0.21"
  spec.add_development_dependency "standard", "1.49.0"
  spec.add_development_dependency "yard", "~> 0.9"
  spec.add_development_dependency "pry-byebug", "~> 3.10"
end
