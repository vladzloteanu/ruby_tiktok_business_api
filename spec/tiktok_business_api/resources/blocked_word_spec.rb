# frozen_string_literal: true

require "spec_helper"

RSpec.describe TiktokBusinessApi::Resources::BlockedWord do
  let(:client) { TiktokBusinessApi::Client.new(app_id: "test_app_id", secret: "test_secret") }
  let(:blocked_words) { described_class.new(client) }
  let(:advertiser_id) { "7299876543210987654" }
  let(:ok) { {"code" => 0, "message" => "OK", "data" => {}}.to_json }

  def words_page(words, page:, total_page:)
    {
      "code" => 0,
      "message" => "OK",
      "data" => {
        "blocked_words" => words,
        "page_info" => {"page" => page, "page_size" => 1, "total_page" => total_page}
      }
    }.to_json
  end

  describe "#list" do
    it "sends page_info as JSON" do
      stub = stub_request(:get, "#{client.config.api_base_url}v1.3/blockedword/list/")
        .with(query: {advertiser_id: advertiser_id, page_info: {page: 1, page_size: 100}.to_json})
        .to_return(status: 200, body: words_page(["scam"], page: 1, total_page: 1))

      expect(blocked_words.list(advertiser_id: advertiser_id)["blocked_words"]).to eq(["scam"])
      expect(stub).to have_been_requested
    end
  end

  describe "#list_all" do
    before do
      stub_request(:get, "#{client.config.api_base_url}v1.3/blockedword/list/")
        .with(query: hash_including(page_info: {page: 1, page_size: 1}.to_json))
        .to_return(status: 200, body: words_page([{"word" => "scam"}], page: 1, total_page: 2))
      stub_request(:get, "#{client.config.api_base_url}v1.3/blockedword/list/")
        .with(query: hash_including(page_info: {page: 2, page_size: 1}.to_json))
        .to_return(status: 200, body: words_page(["spam"], page: 2, total_page: 2))
    end

    it "returns every word, whether TikTok sends strings or objects" do
      expect(blocked_words.list_all(advertiser_id: advertiser_id, page_size: 1)).to eq(%w[scam spam])
    end
  end

  describe "#create, #update and #delete" do
    it "posts the words" do
      create = stub_request(:post, "#{client.config.api_base_url}v1.3/blockedword/create/")
        .with(body: {advertiser_id: advertiser_id, blocked_words: %w[scam spam]}.to_json)
        .to_return(status: 200, body: ok)
      update = stub_request(:post, "#{client.config.api_base_url}v1.3/blockedword/update/")
        .with(body: {advertiser_id: advertiser_id, old_word: "scam", new_word: "scams"}.to_json)
        .to_return(status: 200, body: ok)
      delete = stub_request(:post, "#{client.config.api_base_url}v1.3/blockedword/delete/")
        .with(body: {advertiser_id: advertiser_id, blocked_words: ["spam"]}.to_json)
        .to_return(status: 200, body: ok)

      blocked_words.create(advertiser_id: advertiser_id, blocked_words: %w[scam spam])
      blocked_words.update(advertiser_id: advertiser_id, old_word: "scam", new_word: "scams")
      blocked_words.delete(advertiser_id: advertiser_id, blocked_words: "spam")

      expect(create).to have_been_requested
      expect(update).to have_been_requested
      expect(delete).to have_been_requested
    end
  end

  describe "#check" do
    it "sends the words as JSON" do
      stub = stub_request(:get, "#{client.config.api_base_url}v1.3/blockedword/check/")
        .with(query: {advertiser_id: advertiser_id, blocked_words: '["scam"]'})
        .to_return(status: 200, body: ok)

      blocked_words.check(advertiser_id: advertiser_id, blocked_words: ["scam"])

      expect(stub).to have_been_requested
    end
  end

  describe "#create_task and #check_task" do
    it "creates an export task and checks it" do
      create = stub_request(:post, "#{client.config.api_base_url}v1.3/blockedword/task/create/")
        .with(body: {advertiser_id: advertiser_id}.to_json)
        .to_return(status: 200, body: {"code" => 0, "data" => {"task_id" => "t1"}}.to_json)
      check = stub_request(:get, "#{client.config.api_base_url}v1.3/blockedword/task/check/")
        .with(query: {advertiser_id: advertiser_id, task_id: "t1"})
        .to_return(status: 200, body: ok)

      blocked_words.check_task(advertiser_id: advertiser_id, task_id: blocked_words.create_task(advertiser_id: advertiser_id)["task_id"])

      expect(create).to have_been_requested
      expect(check).to have_been_requested
    end
  end
end
