# frozen_string_literal: true

module TiktokBusinessApi
  module Resources
    # Ad resource for Upgraded Smart+ Campaigns
    #
    # Endpoints under `v1.3/smart_plus/ad/*` — used to manage ads (each ad
    # holds up to 50 materials in its `creative_list`) inside an Upgraded
    # Smart+ ad group. Regular `client.ads` and the legacy `client.spcs`
    # resource both fail against `UPGRADED_SMART_PLUS` campaigns.
    #
    # Note: ads in this namespace are identified by `smart_plus_ad_id`
    # (NOT `ad_id`). Filtering by `ad_ids` is silently ignored; use
    # `smart_plus_ad_ids` instead.
    class UpgradedSpcAd < BaseResource
      def base_path
        "#{api_version}/smart_plus/ad"
      end

      # List Upgraded Smart+ ads
      #
      # @param advertiser_id [String] Advertiser ID (required)
      # @param campaign_id [String] Filter by campaign ID (optional)
      # @param adgroup_id [String] Filter by ad group ID (optional)
      # @param smart_plus_ad_id [String] Filter by ad ID (optional)
      # @param fields [Array<String>] Fields to return (optional)
      # @param page [Integer] Page number (default: 1)
      # @param page_size [Integer] Page size (default: 10, max: 1000)
      # @param filtering [Hash] Filtering conditions (optional)
      # @return [Array<Hash>] List of ads
      def list(advertiser_id:, campaign_id: nil, adgroup_id: nil, smart_plus_ad_id: nil,
        fields: nil, page: 1, page_size: 10, filtering: {}, &block)
        filtering = filtering.dup
        filtering[:campaign_ids] = [campaign_id] if campaign_id
        filtering[:adgroup_ids] = [adgroup_id] if adgroup_id
        filtering[:smart_plus_ad_ids] = [smart_plus_ad_id] if smart_plus_ad_id

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

      # Get a single ad by ID
      #
      # @param advertiser_id [String] Advertiser ID (required)
      # @param smart_plus_ad_id [String] Ad ID (required)
      # @param fields [Array<String>] Fields to return (optional)
      # @return [Hash, nil] Ad data or nil if not found
      def get(advertiser_id:, smart_plus_ad_id:, fields: nil)
        list(
          advertiser_id: advertiser_id,
          fields: fields,
          filtering: {smart_plus_ad_ids: [smart_plus_ad_id]}
        ).first
      end

      # Create one or more ads in an Upgraded Smart+ ad group
      #
      # @param advertiser_id [String] Advertiser ID (required)
      # @param adgroup_id [String] Ad group ID (required)
      # @param params [Hash] Additional ad payload (ad_name, creative_list,
      #   ad_text_list, landing_page_url_list, ad_configuration, etc.)
      # @return [Hash] Created ad data
      def create(advertiser_id:, adgroup_id:, **params)
        body = {
          advertiser_id: advertiser_id,
          adgroup_id: adgroup_id
        }.merge(params)

        response = _http_post("create/", body)
        response["data"]
      end

      # Update an ad (incremental update)
      #
      # @param advertiser_id [String] Advertiser ID (required)
      # @param smart_plus_ad_id [String] Ad ID (required)
      # @param params [Hash] Fields to update (creative_list, ad_text_list,
      #   landing_page_url_list, ad_configuration, ad_name, etc.)
      # @return [Hash] Updated ad data
      def update(advertiser_id:, smart_plus_ad_id:, **params)
        body = {
          advertiser_id: advertiser_id,
          smart_plus_ad_id: smart_plus_ad_id
        }.merge(params)

        response = _http_post("update/", body)
        response["data"]
      end

      # Update operation status of ads
      #
      # @param advertiser_id [String] Advertiser ID (required)
      # @param smart_plus_ad_ids [Array<String>] Ad IDs (required)
      # @param operation_status [String] New status: ENABLE or DISABLE (required)
      # @return [Hash] Result data
      def update_status(advertiser_id:, smart_plus_ad_ids:, operation_status:, **params)
        body = {
          advertiser_id: advertiser_id,
          smart_plus_ad_ids: smart_plus_ad_ids,
          operation_status: operation_status
        }.merge(params)

        response = _http_post("status/update/", body)
        response["data"]
      end

      # Update the status of individual creative materials inside an ad
      #
      # @param advertiser_id [String] Advertiser ID (required)
      # @param smart_plus_ad_id [String] Ad ID (required)
      # @param materials [Array<Hash>] Material status updates (required)
      # @return [Hash] Result data
      def update_material_status(advertiser_id:, smart_plus_ad_id:, materials:, **params)
        body = {
          advertiser_id: advertiser_id,
          smart_plus_ad_id: smart_plus_ad_id,
          materials: materials
        }.merge(params)

        response = _http_post("material_status/update/", body)
        response["data"]
      end
    end
  end
end
