# frozen_string_literal: true

module TiktokBusinessApi
  module Resources
    # Upgraded Smart+ Campaigns resource for the TikTok Business API
    #
    # This resource provides access to the Upgraded Smart+ Campaign endpoints,
    # which offer a unified workflow for both manual and Smart+ features.
    class UpgradedSpc < BaseResource
      def base_path
        "#{api_version}/smart_plus/campaign"
      end

      # List Upgraded Smart+ Campaigns
      #
      # @param advertiser_id [String] Advertiser ID (required)
      # @param fields [Array<String>] Fields to return (optional)
      # @param page [Integer] Page number (default: 1)
      # @param page_size [Integer] Page size (default: 10, max: 1000)
      # @param filtering [Hash] Filtering conditions (optional)
      # @return [Array<Hash>] List of campaigns
      def list(advertiser_id:, fields: nil, page: 1, page_size: 10, filtering: {}, &block)
        params = {advertiser_id: advertiser_id, page: page, page_size: page_size}
        params[:fields] = fields.to_json if fields
        params[:filtering] = filtering.to_json unless filtering.empty?

        response = _http_get("get/", params)

        if block_given?
          items = response.dig("data", "list") || []
          items.each(&block)
          response
        else
          response.dig("data", "list") || []
        end
      end

      # List all Upgraded Smart+ Campaigns with automatic pagination
      #
      # @param advertiser_id [String] Advertiser ID (required)
      # @param fields [Array<String>] Fields to return (optional)
      # @param page_size [Integer] Page size (default: 100, max: 1000)
      # @param filtering [Hash] Filtering conditions (optional)
      # @yield [campaign] Block to process each campaign
      # @return [Array<Hash>] All campaigns if no block given
      def list_all(advertiser_id:, fields: nil, page_size: 100, filtering: {}, &block)
        items = []
        page = 1
        has_more = true

        while has_more
          params = {advertiser_id: advertiser_id, page: page, page_size: page_size}
          params[:fields] = fields.to_json if fields
          params[:filtering] = filtering.to_json unless filtering.empty?

          response = _http_get("get/", params)
          current_items = response.dig("data", "list") || []

          if block_given?
            current_items.each(&block)
          else
            items.concat(current_items)
          end

          page_info = response.dig("data", "page_info") || {}
          total_number = page_info["total_number"] || 0
          total_fetched = page * page_size

          has_more = total_number > 0 && total_fetched < total_number
          page += 1

          break if current_items.empty?
        end

        block_given? ? nil : items
      end

      # Get a single Upgraded Smart+ Campaign by ID
      #
      # @param advertiser_id [String] Advertiser ID (required)
      # @param campaign_id [String] Campaign ID (required)
      # @param fields [Array<String>] Fields to return (optional)
      # @return [Hash, nil] Campaign data or nil if not found
      def get(advertiser_id:, campaign_id:, fields: nil)
        filtering = {campaign_ids: [campaign_id]}
        result = list(advertiser_id: advertiser_id, fields: fields, filtering: filtering)
        result&.first
      end

      # Create an Upgraded Smart+ Campaign
      #
      # @param advertiser_id [String] Advertiser ID (required)
      # @param campaign_name [String] Campaign name (required, max 512 chars)
      # @param objective_type [String] Advertising objective (required): APP_PROMOTION, WEB_CONVERSIONS, LEAD_GENERATION
      # @param request_id [String] Idempotency key (required) - 64-bit integer as string
      # @param params [Hash] Additional parameters (operation_status, budget, budget_mode, etc.)
      # @return [Hash] Created campaign data
      def create(advertiser_id:, campaign_name:, objective_type:, request_id:, **params)
        body = {
          advertiser_id: advertiser_id,
          campaign_name: campaign_name,
          objective_type: objective_type,
          request_id: request_id
        }.merge(params)

        response = _http_post("create/", body)
        response["data"]
      end

      # Update an Upgraded Smart+ Campaign (incremental update)
      #
      # @param advertiser_id [String] Advertiser ID (required)
      # @param campaign_id [String] Campaign ID (required)
      # @param params [Hash] Fields to update (campaign_name, budget)
      # @return [Hash] Updated campaign data
      def update(advertiser_id:, campaign_id:, **params)
        body = {
          advertiser_id: advertiser_id,
          campaign_id: campaign_id
        }.merge(params)

        response = _http_post("update/", body)
        response["data"]
      end

      # Update operation status of Upgraded Smart+ Campaigns
      #
      # @param advertiser_id [String] Advertiser ID (required)
      # @param campaign_ids [Array<String>] Campaign IDs to update (required)
      # @param operation_status [String] New status: ENABLE or DISABLE (required)
      # @return [Hash] Result data
      def update_status(advertiser_id:, campaign_ids:, operation_status:, **params)
        body = {
          advertiser_id: advertiser_id,
          campaign_ids: campaign_ids,
          operation_status: operation_status
        }.merge(params)

        response = _http_post("status/update/", body)
        response["data"]
      end
    end
  end
end
