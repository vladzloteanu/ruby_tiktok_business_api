# frozen_string_literal: true

module TiktokBusinessApi
  module Resources
    # Smart+ Material Report resource for the TikTok Business API
    #
    # Provides creative-level performance data for Smart+ campaigns.
    # This allows you to see which creatives (videos/images) perform best
    # within a Smart+ campaign, rather than relying on ad-level aggregation.
    #
    # API Reference:
    # - Overview: GET /open_api/v1.3/smart_plus/material_report/overview/
    # - Breakdown: GET /open_api/v1.3/smart_plus/material_report/breakdown/
    #
    # @example Get overview of material performance
    #   client.smart_plus_material_reports.overview(
    #     advertiser_id: "123456",
    #     campaign_id: "789",
    #     dimensions: ["main_material_id"],
    #     start_date: "2026-01-01",
    #     end_date: "2026-01-18"
    #   )
    #
    # @example Get breakdown by creative
    #   client.smart_plus_material_reports.breakdown(
    #     advertiser_id: "123456",
    #     campaign_id: "789",
    #     dimensions: ["main_material_id"],
    #     start_date: "2026-01-01",
    #     end_date: "2026-01-18",
    #     metrics: ["spend", "impressions", "clicks", "conversions"]
    #   )
    #
    # Available dimensions:
    # - main_material_id: The creative (video/image) ID
    # - ad_text_entity_id: Ad text/copy variation
    # - call_to_action_entity_id: CTA button variation
    # - interactive_add_on_entity_id: Interactive add-on variation
    # - stat_time_day, stat_time_hour, stat_time_week, stat_time_month: Time granularity
    #
    class SmartPlusMaterialReport < BaseResource
      # Get the resource name (used for endpoint paths)
      #
      # @return [String] Resource name
      def resource_name
        "smart_plus/material_report"
      end

      # Get overview of material (creative) performance for a Smart+ campaign
      #
      # @param advertiser_id [String] The advertiser ID
      # @param dimensions [Array<String>] Dimensions to break down by (required)
      #   Available: main_material_id, ad_text_entity_id, call_to_action_entity_id,
      #   interactive_add_on_entity_id, stat_time_day, stat_time_hour, stat_time_week, stat_time_month
      # @param start_date [String] Start date in YYYY-MM-DD format
      # @param end_date [String] End date in YYYY-MM-DD format
      # @param campaign_id [String] The Smart+ campaign ID (optional, filters to specific campaign)
      # @param metrics [Array<String>] Metrics to include (optional)
      # @param filtering [Hash] Additional filtering options (optional)
      # @return [Hash] Overview data with aggregated creative performance
      def overview(advertiser_id:, dimensions:, start_date:, end_date:, campaign_id: nil, metrics: nil, filtering: nil, **params)
        request_params = {
          advertiser_id: advertiser_id,
          dimensions: dimensions.is_a?(Array) ? dimensions.to_json : dimensions,
          start_date: start_date,
          end_date: end_date
        }

        # Add optional parameters
        request_params[:campaign_id] = campaign_id if campaign_id
        request_params[:metrics] = metrics.is_a?(Array) ? metrics.to_json : metrics if metrics
        request_params[:filtering] = filtering.is_a?(Hash) ? filtering.to_json : filtering if filtering
        request_params.merge!(params)

        response = client.request(:get, "#{base_path}/overview/", request_params)
        response["data"]
      end

      # Get breakdown of material (creative) performance for a Smart+ campaign
      #
      # This is the key method for understanding which creatives perform best.
      # It returns performance metrics broken down by the specified dimensions.
      #
      # @param advertiser_id [String] The advertiser ID
      # @param dimensions [Array<String>] Dimensions to break down by (e.g., ["main_material_id"])
      #   Available: main_material_id, ad_text_entity_id, call_to_action_entity_id,
      #   interactive_add_on_entity_id, stat_time_day, stat_time_hour, stat_time_week, stat_time_month
      # @param start_date [String] Start date in YYYY-MM-DD format
      # @param end_date [String] End date in YYYY-MM-DD format
      # @param campaign_id [String] The Smart+ campaign ID (optional, filters to specific campaign)
      # @param metrics [Array<String>] Metrics to include (e.g., ["spend", "impressions", "clicks"])
      # @param filtering [Hash] Additional filtering options (optional)
      # @param sort_field [String] Field to sort by (default: "spend")
      # @param sort_type [String] Sort direction: "ASC" or "DESC" (default: "DESC")
      # @param page [Integer] Page number (default: 1)
      # @param page_size [Integer] Results per page (default: 10, max: 1000)
      # @return [Hash] Breakdown data with per-creative performance metrics
      def breakdown(advertiser_id:, dimensions:, start_date:, end_date:, campaign_id: nil,
        metrics: nil, filtering: nil, sort_field: "spend", sort_type: "DESC",
        page: 1, page_size: 100, **params)
        request_params = {
          advertiser_id: advertiser_id,
          dimensions: dimensions.is_a?(Array) ? dimensions.to_json : dimensions,
          start_date: start_date,
          end_date: end_date,
          sort_field: sort_field,
          sort_type: sort_type,
          page: page,
          page_size: page_size
        }

        # Add optional parameters
        request_params[:campaign_id] = campaign_id if campaign_id
        request_params[:metrics] = metrics.is_a?(Array) ? metrics.to_json : metrics if metrics
        request_params[:filtering] = filtering.is_a?(Hash) ? filtering.to_json : filtering if filtering
        request_params.merge!(params)

        response = client.request(:get, "#{base_path}/breakdown/", request_params)
        response["data"]
      end

      # Get all breakdown results with automatic pagination
      #
      # @param advertiser_id [String] The advertiser ID
      # @param dimensions [Array<String>] Dimensions to break down by
      # @param start_date [String] Start date in YYYY-MM-DD format
      # @param end_date [String] End date in YYYY-MM-DD format
      # @param params [Hash] Additional parameters (same as breakdown method)
      # @return [Array<Hash>] All breakdown records across all pages
      def breakdown_all(advertiser_id:, dimensions:, start_date:, end_date:, **params)
        all_records = []
        page = 1
        page_size = params.delete(:page_size) || 100

        loop do
          result = breakdown(
            advertiser_id: advertiser_id,
            dimensions: dimensions,
            start_date: start_date,
            end_date: end_date,
            page: page,
            page_size: page_size,
            **params
          )

          records = result&.dig("list") || []
          all_records.concat(records)

          # Check if there are more pages
          page_info = result&.dig("page_info") || {}
          break unless page_info["has_more"]

          page += 1
        end

        all_records
      end
    end
  end
end
