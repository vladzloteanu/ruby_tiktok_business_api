# frozen_string_literal: true

module TiktokBusinessApi
  module Resources
    # Ad group resource for Upgraded Smart+ Campaigns
    #
    # Endpoints under `v1.3/smart_plus/adgroup/*` — used to manage ad groups
    # inside an Upgraded Smart+ campaign. Regular `client.adgroups` does not
    # work with `UPGRADED_SMART_PLUS` campaigns.
    class UpgradedSpcAdgroup < BaseResource
      def base_path
        "#{api_version}/smart_plus/adgroup"
      end

      # List Upgraded Smart+ ad groups
      #
      # @param advertiser_id [String] Advertiser ID (required)
      # @param campaign_id [String] Filter by campaign ID (optional)
      # @param fields [Array<String>] Fields to return (optional)
      # @param page [Integer] Page number (default: 1)
      # @param page_size [Integer] Page size (default: 10, max: 1000)
      # @param filtering [Hash] Filtering conditions (optional)
      # @return [Array<Hash>] List of ad groups
      def list(advertiser_id:, campaign_id: nil, fields: nil, page: 1, page_size: 10, filtering: {}, &block)
        filtering = filtering.dup
        filtering[:campaign_ids] = [campaign_id] if campaign_id

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

      # Get a single ad group by ID
      #
      # @param advertiser_id [String] Advertiser ID (required)
      # @param adgroup_id [String] Ad group ID (required)
      # @param fields [Array<String>] Fields to return (optional)
      # @return [Hash, nil] Ad group data or nil if not found
      def get(advertiser_id:, adgroup_id:, fields: nil)
        filtering = {adgroup_ids: [adgroup_id]}
        list(advertiser_id: advertiser_id, fields: fields, filtering: filtering).first
      end

      # Create an ad group
      #
      # @param advertiser_id [String] Advertiser ID (required)
      # @param campaign_id [String] Campaign ID (required)
      # @param adgroup_name [String] Ad group name (required)
      # @param params [Hash] Additional parameters
      # @return [Hash] Created ad group data
      def create(advertiser_id:, campaign_id:, adgroup_name:, **params)
        body = {
          advertiser_id: advertiser_id,
          campaign_id: campaign_id,
          adgroup_name: adgroup_name
        }.merge(params)

        response = _http_post("create/", body)
        response["data"]
      end

      # Update an ad group (incremental update)
      #
      # @param advertiser_id [String] Advertiser ID (required)
      # @param adgroup_id [String] Ad group ID (required)
      # @param params [Hash] Fields to update
      # @return [Hash] Updated ad group data
      def update(advertiser_id:, adgroup_id:, **params)
        body = {
          advertiser_id: advertiser_id,
          adgroup_id: adgroup_id
        }.merge(params)

        response = _http_post("update/", body)
        response["data"]
      end

      # Update operation status of ad groups
      #
      # @param advertiser_id [String] Advertiser ID (required)
      # @param adgroup_ids [Array<String>] Ad group IDs (required)
      # @param operation_status [String] New status: ENABLE or DISABLE (required)
      # @return [Hash] Result data
      def update_status(advertiser_id:, adgroup_ids:, operation_status:, **params)
        body = {
          advertiser_id: advertiser_id,
          adgroup_ids: adgroup_ids,
          operation_status: operation_status
        }.merge(params)

        response = _http_post("status/update/", body)
        response["data"]
      end
    end
  end
end
