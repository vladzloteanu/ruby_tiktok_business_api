# frozen_string_literal: true

module TiktokBusinessApi
  module Resources
    # Business Center resource for the TikTok Business API
    class BusinessCenter < BaseResource
      RESOURCE_NAME = "bc"

      ADVERTISER_ASSET_TYPE = "ADVERTISER"

      # Get a single page of Business Centers accessible with the current access token
      #
      # @param options [Hash] Additional options for the request
      # @option options [String] :bc_id Filter by a specific Business Center ID
      # @option options [String] :scope Business Center scope filter
      # @option options [Integer] :page Page number
      # @option options [Integer] :page_size Number of results per page
      # @return [Array<Hash>] List of Business Centers
      def list(**options, &block)
        params = pagination_params(options)
        params[:bc_id] = options[:bc_id] if options[:bc_id]
        params[:scope] = options[:scope] if options[:scope]

        response = client.request(:get, "/v1.3/bc/get/", params)
        items = response.dig("data", "list") || []
        items.each(&block) if block_given?
        items
      end

      # Get all Business Centers with automatic pagination
      #
      # @param options [Hash] Additional options for the request
      # @yield [business_center] Block to process each Business Center
      # @yieldparam business_center [Hash] Business Center from the response
      # @return [Array<Hash>, nil] All Business Centers if no block is given
      def list_all(**options, &block)
        extra = {}
        extra[:bc_id] = options[:bc_id] if options[:bc_id]
        extra[:scope] = options[:scope] if options[:scope]

        paginate_all("/v1.3/bc/get/", extra, **options, &block)
      end

      # Get a single page of assets of a given type in a Business Center
      #
      # @param bc_id [String] Business Center ID
      # @param asset_type [String] Asset type (e.g. "ADVERTISER")
      # @param admin [Boolean] Use the admin view (all assets in the BC) instead of the member view
      # @param options [Hash] Additional options for the request
      # @option options [String] :child_bc_id Child Business Center ID
      # @option options [Hash] :filtering Filtering conditions
      # @option options [Integer] :page Page number
      # @option options [Integer] :page_size Number of results per page
      # @return [Array<Hash>] List of assets
      def assets(bc_id:, asset_type:, admin: false, **options, &block)
        params = pagination_params(options).merge(bc_id: bc_id, asset_type: asset_type)
        params[:child_bc_id] = options[:child_bc_id] if options[:child_bc_id]
        params[:filtering] = options[:filtering].to_json if options[:filtering]

        response = client.request(:get, asset_path(admin), params)
        items = response.dig("data", "list") || []
        items.each(&block) if block_given?
        items
      end

      # Get all assets of a given type in a Business Center with automatic pagination
      #
      # @param bc_id [String] Business Center ID
      # @param asset_type [String] Asset type (e.g. "ADVERTISER")
      # @param admin [Boolean] Use the admin view (all assets in the BC) instead of the member view
      # @param options [Hash] Additional options for the request
      # @yield [asset] Block to process each asset
      # @yieldparam asset [Hash] Asset from the response
      # @return [Array<Hash>, nil] All assets if no block is given
      def assets_all(bc_id:, asset_type:, admin: false, **options, &block)
        extra = {bc_id: bc_id, asset_type: asset_type}
        extra[:child_bc_id] = options[:child_bc_id] if options[:child_bc_id]
        extra[:filtering] = options[:filtering].to_json if options[:filtering]

        paginate_all(asset_path(admin), extra, **options, &block)
      end

      # Get a single page of ad accounts (advertisers) under a Business Center
      #
      # By default returns the member view (accounts the token's user can access and
      # operate). Pass admin: true for the admin view, which lists every ad account in
      # the BC, including ones the token cannot operate on.
      #
      # @param bc_id [String] Business Center ID
      # @param admin [Boolean] Use the admin view (all accounts in the BC). Defaults to false.
      # @param options [Hash] Additional options for the request
      # @return [Array<Hash>] List of advertiser assets
      def advertisers(bc_id:, admin: false, **options, &block)
        assets(bc_id: bc_id, asset_type: ADVERTISER_ASSET_TYPE, admin: admin, **options, &block)
      end

      # Get all ad accounts (advertisers) under a Business Center with automatic pagination
      #
      # By default returns the member view (accounts the token's user can access and
      # operate). Pass admin: true for the admin view, which lists every ad account in
      # the BC, including ones the token cannot operate on.
      #
      # @param bc_id [String] Business Center ID
      # @param admin [Boolean] Use the admin view (all accounts in the BC). Defaults to false.
      # @param options [Hash] Additional options for the request
      # @yield [advertiser] Block to process each advertiser asset
      # @yieldparam advertiser [Hash] Advertiser asset from the response
      # @return [Array<Hash>, nil] All advertiser assets if no block is given
      def advertisers_all(bc_id:, admin: false, **options, &block)
        assets_all(bc_id: bc_id, asset_type: ADVERTISER_ASSET_TYPE, admin: admin, **options, &block)
      end

      private

      def asset_path(admin)
        admin ? "/v1.3/bc/asset/admin/get/" : "/v1.3/bc/asset/get/"
      end

      def pagination_params(options)
        {
          page: options[:page] || 1,
          page_size: options[:page_size] || 50
        }
      end

      def paginate_all(path, extra_params = {}, **options, &block)
        items = []
        page = 1
        page_size = options[:page_size] || 50
        has_more = true

        while has_more
          request_params = extra_params.merge(page: page, page_size: page_size)
          response = client.request(:get, path, request_params)

          current_items = response.dig("data", "list") || []

          if block_given?
            current_items.each(&block)
          else
            items.concat(current_items)
          end

          page_info = response.dig("data", "page_info") || {}
          total_page = page_info["total_page"].to_i
          has_more = total_page > page && !current_items.empty?
          page += 1
        end

        block_given? ? nil : items
      end
    end
  end
end
