# frozen_string_literal: true

require "faraday"
require "faraday/retry"
require "faraday/follow_redirects"
require "faraday/multipart"
require "json"

require_relative "tiktok_business_api/version"
require_relative "tiktok_business_api/config"
require_relative "tiktok_business_api/errors"
require_relative "tiktok_business_api/utils"
require_relative "tiktok_business_api/client"
require_relative "tiktok_business_api/auth"

# Resources
require_relative "tiktok_business_api/resources/base_resource"
require_relative "tiktok_business_api/resources/crud_resource"
require_relative "tiktok_business_api/resources/campaign"
require_relative "tiktok_business_api/resources/adgroup"
require_relative "tiktok_business_api/resources/ad"
require_relative "tiktok_business_api/resources/image"
require_relative "tiktok_business_api/resources/video"
require_relative "tiktok_business_api/resources/identity"
require_relative "tiktok_business_api/resources/account"
require_relative "tiktok_business_api/resources/reporting"
require_relative "tiktok_business_api/resources/spc"
require_relative "tiktok_business_api/resources/smart_plus_material_report"

module TiktokBusinessApi
  class << self
    attr_accessor :config

    # Configure the TikTok Business API client
    #
    # @yield [config] Configuration object that can be modified
    # @return [TiktokBusinessApi::Config] The configuration object
    def configure
      self.config ||= Config.new
      yield(config) if block_given?
      config
    end

    # Create a new client instance
    #
    # @param options [Hash] Optional configuration overrides
    # @return [TiktokBusinessApi::Client] A new client instance
    def client(options = {})
      TiktokBusinessApi::Client.new(options)
    end
  end
end
