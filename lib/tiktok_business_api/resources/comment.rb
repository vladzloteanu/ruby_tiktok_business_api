# frozen_string_literal: true

module TiktokBusinessApi
  module Resources
    # Comment resource for the TikTok Business API (comments on ads)
    class Comment < BaseResource
      RESOURCE_NAME = "comment"

      # Comment statuses accepted by #update_status
      HIDDEN = "HIDDEN"
      PUBLIC = "PUBLIC"

      # Get a single page of comments
      #
      # @param advertiser_id [String] Advertiser ID
      # @param search_field [String] Field to search by (e.g. "ADGROUP_ID")
      # @param search_value [String] Value of the search field
      # @param start_time [String] Start date, "YYYY-MM-DD"
      # @param end_time [String] End date, "YYYY-MM-DD"
      # @param options [Hash] Additional options for the request
      # @option options [String] :sort_field Sort field (default CREATE_TIME)
      # @option options [String] :sort_type Sort order, ASC or DESC (default DESC)
      # @option options [Array<String>] :comment_type Comment types (COMMENT, REPLY)
      # @option options [Array<String>] :comment_status Comment statuses (PUBLIC, HIDDEN)
      # @option options [Integer] :page Page number
      # @option options [Integer] :page_size Number of results per page
      # @return [Hash] Response data with "comments" and "page_info"
      def list(advertiser_id:, search_field:, search_value:, start_time:, end_time:, **options, &block)
        params = list_params(advertiser_id, search_field, search_value, start_time, end_time, options)
        params[:page] = options[:page] || 1
        params[:page_size] = options[:page_size] || 50

        data = client.request(:get, "#{base_path}/list/", params)["data"] || {}
        (data["comments"] || []).each(&block) if block_given?
        data
      end

      # Get all comments with automatic pagination
      #
      # @param advertiser_id [String] Advertiser ID
      # @param search_field [String] Field to search by (e.g. "ADGROUP_ID")
      # @param search_value [String] Value of the search field
      # @param start_time [String] Start date, "YYYY-MM-DD"
      # @param end_time [String] End date, "YYYY-MM-DD"
      # @param options [Hash] Same options as #list
      # @yield [comment] Block to process each comment
      # @yieldparam comment [Hash] Comment from the response
      # @return [Array<Hash>, nil] All comments if no block is given
      def list_all(advertiser_id:, search_field:, search_value:, start_time:, end_time:, **options, &block)
        comments = []
        page = options[:page] || 1

        loop do
          data = list(advertiser_id: advertiser_id, search_field: search_field, search_value: search_value,
            start_time: start_time, end_time: end_time, **options, page: page)
          current = data["comments"] || []
          block_given? ? current.each(&block) : comments.concat(current)

          break if current.empty? || page >= data.dig("page_info", "total_page").to_i

          page += 1
        end

        block_given? ? nil : comments
      end

      # Get the comments related to a comment (its thread)
      #
      # @param advertiser_id [String] Advertiser ID
      # @param comment_id [String] Comment ID
      # @param comment_type [String] Comment type (COMMENT or REPLY)
      # @param options [Hash] Additional options for the request
      # @option options [String] :original_comment_id ID of the top-level comment of a reply
      # @option options [String] :app App the comment was posted on (default TIKTOK)
      # @option options [Integer] :page Page number
      # @option options [Integer] :page_size Number of results per page
      # @return [Hash] Response data
      def references(advertiser_id:, comment_id:, comment_type:, **options)
        params = {advertiser_id: advertiser_id, comment_id: comment_id, comment_type: comment_type}
        params[:original_comment_id] = options[:original_comment_id] if options[:original_comment_id]
        params[:app] = options[:app] if options[:app]
        params[:page] = options[:page] if options[:page]
        params[:page_size] = options[:page_size] if options[:page_size]

        client.request(:get, "#{base_path}/reference/", params)["data"]
      end

      # Hide or unhide comments
      #
      # @param advertiser_id [String] Advertiser ID
      # @param comment_ids [Array<String>] Comment IDs
      # @param operation [String] HIDDEN or PUBLIC
      # @param ad_type [String] Ad type (default BIDDING on TikTok's side)
      # @return [Hash] Response data
      def update_status(advertiser_id:, comment_ids:, operation:, ad_type: nil)
        params = {advertiser_id: advertiser_id, comment_ids: Array(comment_ids).map(&:to_s), operation: operation}
        params[:ad_type] = ad_type if ad_type

        client.request(:post, "#{base_path}/status/update/", params)["data"]
      end

      # Hide comments
      #
      # @param advertiser_id [String] Advertiser ID
      # @param comment_ids [Array<String>] Comment IDs
      # @return [Hash] Response data
      def hide(advertiser_id:, comment_ids:)
        update_status(advertiser_id: advertiser_id, comment_ids: comment_ids, operation: HIDDEN)
      end

      # Make hidden comments public again
      #
      # @param advertiser_id [String] Advertiser ID
      # @param comment_ids [Array<String>] Comment IDs
      # @return [Hash] Response data
      def unhide(advertiser_id:, comment_ids:)
        update_status(advertiser_id: advertiser_id, comment_ids: comment_ids, operation: PUBLIC)
      end

      # Delete a comment
      #
      # @param advertiser_id [String] Advertiser ID
      # @param comment_id [String] Comment ID
      # @param ad_id [String] ID of the ad the comment belongs to
      # @param tiktok_item_id [String] ID of the TikTok post the comment belongs to
      # @param identity_id [String] Identity ID of the ad
      # @param identity_type [String] Identity type of the ad
      # @return [Hash] Response data
      def delete(advertiser_id:, comment_id:, ad_id:, tiktok_item_id:, identity_id:, identity_type:)
        params = {
          advertiser_id: advertiser_id,
          comment_id: comment_id.to_s,
          ad_id: ad_id.to_s,
          tiktok_item_id: tiktok_item_id.to_s,
          identity_id: identity_id.to_s,
          identity_type: identity_type
        }

        client.request(:post, "#{base_path}/delete/", params)["data"]
      end

      # Reply to a comment
      #
      # @param advertiser_id [String] Advertiser ID
      # @param comment_id [String] ID of the comment to reply to
      # @param ad_id [String] ID of the ad the comment belongs to
      # @param tiktok_item_id [String] ID of the TikTok post the comment belongs to
      # @param identity_id [String] Identity ID of the ad
      # @param identity_type [String] Identity type of the ad
      # @param text [String] Reply text
      # @param comment_type [String] Type of the posted comment (default REPLY)
      # @return [Hash] Response data, with the new "comment_id"
      def post(advertiser_id:, comment_id:, ad_id:, tiktok_item_id:, identity_id:, identity_type:, text:, comment_type: "REPLY")
        params = {
          advertiser_id: advertiser_id,
          comment_id: comment_id.to_s,
          comment_type: comment_type,
          ad_id: ad_id.to_s,
          tiktok_item_id: tiktok_item_id.to_s,
          identity_id: identity_id.to_s,
          identity_type: identity_type,
          text: text
        }

        client.request(:post, "#{base_path}/post/", params)["data"]
      end

      # Create an asynchronous comment export task
      #
      # @param advertiser_id [String] Advertiser ID
      # @param search_field [String] Field to search by (e.g. "ADGROUP_ID")
      # @param search_value [String] Value of the search field
      # @param start_time [String] Start date, "YYYY-MM-DD"
      # @param end_time [String] End date, "YYYY-MM-DD"
      # @param options [Hash] Additional options for the request
      # @option options [Array<String>] :comment_ids Comment IDs
      # @option options [Array<String>] :comment_type Comment types
      # @option options [Array<String>] :comment_status Comment statuses
      # @option options [String] :sort_field Sort field
      # @option options [String] :sort_type Sort order
      # @option options [String] :lang Language of the export (default EN)
      # @return [Hash] Response data, with the "task_id"
      def create_task(advertiser_id:, search_field:, search_value:, start_time:, end_time:, **options)
        params = {
          advertiser_id: advertiser_id,
          search_field: search_field,
          search_value: search_value.to_s,
          start_time: start_time,
          end_time: end_time
        }
        %i[comment_ids comment_type comment_status sort_field sort_type lang].each do |key|
          params[key] = options[key] if options[key]
        end

        client.request(:post, "#{base_path}/task/create/", params)["data"]
      end

      # Check the status of a comment export task
      #
      # @param advertiser_id [String] Advertiser ID
      # @param task_id [String] Task ID returned by #create_task
      # @param source [String] Ad source (default BIDDING on TikTok's side)
      # @return [Hash] Response data
      def check_task(advertiser_id:, task_id:, source: nil)
        params = {advertiser_id: advertiser_id, task_id: task_id}
        params[:source] = source if source

        client.request(:get, "#{base_path}/task/check/", params)["data"]
      end

      private

      def list_params(advertiser_id, search_field, search_value, start_time, end_time, options)
        params = {
          advertiser_id: advertiser_id,
          search_field: search_field,
          search_value: search_value.to_s,
          start_time: start_time,
          end_time: end_time
        }
        params[:sort_field] = options[:sort_field] if options[:sort_field]
        params[:sort_type] = options[:sort_type] if options[:sort_type]
        params[:comment_type] = Array(options[:comment_type]).to_json if options[:comment_type]
        params[:comment_status] = Array(options[:comment_status]).to_json if options[:comment_status]
        params
      end
    end
  end
end
