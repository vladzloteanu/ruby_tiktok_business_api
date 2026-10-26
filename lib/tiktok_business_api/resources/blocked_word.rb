# frozen_string_literal: true

module TiktokBusinessApi
  module Resources
    # Blocked word resource for the TikTok Business API
    #
    # Blocked words are enforced by TikTok itself: comments containing one of them
    # are hidden from everyone but their author.
    class BlockedWord < BaseResource
      RESOURCE_NAME = "blockedword"

      # Get the resource name (used for endpoint paths)
      #
      # @return [String] Resource name
      def resource_name
        RESOURCE_NAME
      end

      # Get a single page of blocked words of an ad account
      #
      # @param advertiser_id [String] Advertiser ID
      # @param page [Integer] Page number
      # @param page_size [Integer] Number of results per page
      # @return [Hash] Response data with the blocked words and "page_info"
      def list(advertiser_id:, page: 1, page_size: 100, &block)
        params = {advertiser_id: advertiser_id, page_info: {page: page, page_size: page_size}.to_json}

        data = client.request(:get, "#{base_path}/list/", params)["data"] || {}
        words(data).each(&block) if block_given?
        data
      end

      # Get every blocked word of an ad account with automatic pagination
      #
      # @param advertiser_id [String] Advertiser ID
      # @param page_size [Integer] Number of results per page
      # @yield [word] Block to process each blocked word
      # @yieldparam word [String] Blocked word
      # @return [Array<String>, nil] All blocked words if no block is given
      def list_all(advertiser_id:, page_size: 100, &block)
        all_words = []
        page = 1

        loop do
          data = list(advertiser_id: advertiser_id, page: page, page_size: page_size)
          current = words(data)
          block_given? ? current.each(&block) : all_words.concat(current)

          break if current.empty? || page >= data.dig("page_info", "total_page").to_i

          page += 1
        end

        block_given? ? nil : all_words
      end

      # Add blocked words to an ad account
      #
      # @param advertiser_id [String] Advertiser ID
      # @param blocked_words [Array<String>] Words to block
      # @return [Hash] Response data
      def create(advertiser_id:, blocked_words:)
        client.request(:post, "#{base_path}/create/", {advertiser_id: advertiser_id, blocked_words: Array(blocked_words)})["data"]
      end

      # Replace a blocked word
      #
      # @param advertiser_id [String] Advertiser ID
      # @param old_word [String] Blocked word to replace
      # @param new_word [String] New blocked word
      # @return [Hash] Response data
      def update(advertiser_id:, old_word:, new_word:)
        client.request(:post, "#{base_path}/update/", {advertiser_id: advertiser_id, old_word: old_word, new_word: new_word})["data"]
      end

      # Remove blocked words from an ad account
      #
      # @param advertiser_id [String] Advertiser ID
      # @param blocked_words [Array<String>] Words to unblock
      # @return [Hash] Response data
      def delete(advertiser_id:, blocked_words:)
        client.request(:post, "#{base_path}/delete/", {advertiser_id: advertiser_id, blocked_words: Array(blocked_words)})["data"]
      end

      # Check whether words are blocked on an ad account
      #
      # @param advertiser_id [String] Advertiser ID
      # @param blocked_words [Array<String>] Words to check
      # @return [Hash] Response data
      def check(advertiser_id:, blocked_words:)
        client.request(:get, "#{base_path}/check/", {advertiser_id: advertiser_id, blocked_words: Array(blocked_words).to_json})["data"]
      end

      # Create an asynchronous blocked words export task
      #
      # @param advertiser_id [String] Advertiser ID
      # @param blocked_words [Array<String>] Words to export (all when omitted)
      # @param lang [String] Language of the export (default EN on TikTok's side)
      # @return [Hash] Response data, with the "task_id"
      def create_task(advertiser_id:, blocked_words: nil, lang: nil)
        params = {advertiser_id: advertiser_id}
        params[:blocked_words] = Array(blocked_words) if blocked_words
        params[:lang] = lang if lang

        client.request(:post, "#{base_path}/task/create/", params)["data"]
      end

      # Check the status of a blocked words export task
      #
      # @param advertiser_id [String] Advertiser ID
      # @param task_id [String] Task ID returned by #create_task
      # @return [Hash] Response data
      def check_task(advertiser_id:, task_id:)
        client.request(:get, "#{base_path}/task/check/", {advertiser_id: advertiser_id, task_id: task_id})["data"]
      end

      private

      def words(data)
        Array(data["blocked_words"] || data["list"]).map { |item| item.is_a?(Hash) ? (item["word"] || item["blocked_word"]) : item }.compact
      end
    end
  end
end
