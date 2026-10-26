# frozen_string_literal: true

require "spec_helper"

RSpec.describe TiktokBusinessApi::Resources::Comment do
  let(:client) { TiktokBusinessApi::Client.new(app_id: "test_app_id", secret: "test_secret") }
  let(:comments) { described_class.new(client) }
  let(:advertiser_id) { "7299876543210987654" }
  let(:ok) { {"code" => 0, "message" => "OK", "data" => {}}.to_json }
  let(:list_args) do
    {advertiser_id: advertiser_id, search_field: "ADGROUP_ID", search_value: "1800000000000001", start_time: "2026-10-01", end_time: "2026-10-26"}
  end

  def comments_page(ids, page:, total_page:)
    {
      "code" => 0,
      "message" => "OK",
      "data" => {
        "comments" => ids.map { |id| {"comment_id" => id, "comment_type" => "COMMENT", "content" => "Comment #{id}"} },
        "page_info" => {"page" => page, "page_size" => 50, "total_page" => total_page}
      }
    }.to_json
  end

  describe "#list" do
    it "sends the search window and returns the response data" do
      stub = stub_request(:get, "#{client.config.api_base_url}v1.3/comment/list/")
        .with(query: hash_including(
          advertiser_id: advertiser_id, search_field: "ADGROUP_ID", search_value: "1800000000000001",
          start_time: "2026-10-01", end_time: "2026-10-26", page: "1", page_size: "50",
          comment_status: '["HIDDEN"]'
        ))
        .to_return(status: 200, body: comments_page(%w[1 2], page: 1, total_page: 1))

      data = comments.list(**list_args, comment_status: ["HIDDEN"])

      expect(stub).to have_been_requested
      expect(data["comments"].map { |comment| comment["comment_id"] }).to eq(%w[1 2])
    end
  end

  describe "#list_all" do
    before do
      stub_request(:get, "#{client.config.api_base_url}v1.3/comment/list/")
        .with(query: hash_including(page: "1"))
        .to_return(status: 200, body: comments_page(%w[1], page: 1, total_page: 2))
      stub_request(:get, "#{client.config.api_base_url}v1.3/comment/list/")
        .with(query: hash_including(page: "2"))
        .to_return(status: 200, body: comments_page(%w[2], page: 2, total_page: 2))
    end

    it "paginates through every comment" do
      expect(comments.list_all(**list_args).map { |comment| comment["comment_id"] }).to eq(%w[1 2])
    end

    it "yields each comment to a block" do
      yielded = []
      expect(comments.list_all(**list_args) { |comment| yielded << comment["comment_id"] }).to be_nil
      expect(yielded).to eq(%w[1 2])
    end
  end

  describe "#references" do
    it "requests the thread of a comment" do
      stub = stub_request(:get, "#{client.config.api_base_url}v1.3/comment/reference/")
        .with(query: hash_including(advertiser_id: advertiser_id, comment_id: "42", comment_type: "REPLY", original_comment_id: "41"))
        .to_return(status: 200, body: {"code" => 0, "data" => {"comments" => []}}.to_json)

      expect(comments.references(advertiser_id: advertiser_id, comment_id: "42", comment_type: "REPLY", original_comment_id: "41")).to eq("comments" => [])
      expect(stub).to have_been_requested
    end
  end

  describe "#hide and #unhide" do
    it "updates the comment status" do
      hide = stub_request(:post, "#{client.config.api_base_url}v1.3/comment/status/update/")
        .with(body: {advertiser_id: advertiser_id, comment_ids: ["42"], operation: "HIDDEN"}.to_json)
        .to_return(status: 200, body: ok)
      unhide = stub_request(:post, "#{client.config.api_base_url}v1.3/comment/status/update/")
        .with(body: {advertiser_id: advertiser_id, comment_ids: ["42"], operation: "PUBLIC"}.to_json)
        .to_return(status: 200, body: ok)

      comments.hide(advertiser_id: advertiser_id, comment_ids: [42])
      comments.unhide(advertiser_id: advertiser_id, comment_ids: ["42"])

      expect(hide).to have_been_requested
      expect(unhide).to have_been_requested
    end
  end

  describe "#delete" do
    it "sends the ad and identity of the comment" do
      stub = stub_request(:post, "#{client.config.api_base_url}v1.3/comment/delete/")
        .with(body: hash_including(advertiser_id: advertiser_id, comment_id: "42", ad_id: "7", tiktok_item_id: "8", identity_id: "9", identity_type: "CUSTOMIZED_USER"))
        .to_return(status: 200, body: ok)

      comments.delete(advertiser_id: advertiser_id, comment_id: 42, ad_id: 7, tiktok_item_id: 8, identity_id: 9, identity_type: "CUSTOMIZED_USER")

      expect(stub).to have_been_requested
    end
  end

  describe "#post" do
    it "posts a reply and returns the new comment id" do
      stub = stub_request(:post, "#{client.config.api_base_url}v1.3/comment/post/")
        .with(body: hash_including(comment_id: "42", comment_type: "REPLY", text: "Thanks!", ad_id: "7"))
        .to_return(status: 200, body: {"code" => 0, "data" => {"comment_id" => "43"}}.to_json)

      data = comments.post(advertiser_id: advertiser_id, comment_id: "42", ad_id: "7", tiktok_item_id: "8",
        identity_id: "9", identity_type: "CUSTOMIZED_USER", text: "Thanks!")

      expect(stub).to have_been_requested
      expect(data["comment_id"]).to eq("43")
    end
  end

  describe "#create_task and #check_task" do
    it "creates an export task and checks it" do
      create = stub_request(:post, "#{client.config.api_base_url}v1.3/comment/task/create/")
        .with(body: hash_including(search_field: "ADGROUP_ID", lang: "FR"))
        .to_return(status: 200, body: {"code" => 0, "data" => {"task_id" => "t1"}}.to_json)
      check = stub_request(:get, "#{client.config.api_base_url}v1.3/comment/task/check/")
        .with(query: {advertiser_id: advertiser_id, task_id: "t1"})
        .to_return(status: 200, body: {"code" => 0, "data" => {"status" => "SUCCESS"}}.to_json)

      task_id = comments.create_task(**list_args, lang: "FR")["task_id"]

      expect(comments.check_task(advertiser_id: advertiser_id, task_id: task_id)).to eq("status" => "SUCCESS")
      expect(create).to have_been_requested
      expect(check).to have_been_requested
    end
  end

  describe "errors" do
    it "raises when TikTok answers a non-zero code" do
      stub_request(:post, "#{client.config.api_base_url}v1.3/comment/delete/")
        .to_return(status: 200, body: {"code" => 40002, "message" => "Comment cannot be deleted"}.to_json)

      expect {
        comments.delete(advertiser_id: advertiser_id, comment_id: "42", ad_id: "0", tiktok_item_id: "8", identity_id: "", identity_type: "")
      }.to raise_error(TiktokBusinessApi::Error)
    end
  end
end
