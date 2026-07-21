# frozen_string_literal: true

require "spec_helper"

RSpec.describe TiktokBusinessApi::Resources::BusinessCenter do
  let(:client) { TiktokBusinessApi::Client.new(app_id: "test_app_id", secret: "test_secret") }
  let(:business_center) { described_class.new(client) }
  let(:bc_id) { "7441261844632846353" }

  describe "#list" do
    let(:response) do
      {
        "code" => 0,
        "message" => "OK",
        "data" => {
          "list" => [
            {"bc_info" => {"bc_id" => "7307238303143624705", "name" => "Dolead Business Center"}},
            {"bc_info" => {"bc_id" => bc_id, "name" => "Dolead Incorporated"}}
          ],
          "page_info" => {
            "total_number" => 2,
            "page" => 1,
            "page_size" => 50,
            "total_page" => 1
          }
        }
      }
    end

    before do
      stub_request(:get, "#{client.config.api_base_url}v1.3/bc/get/")
        .with(query: hash_including(page: "1", page_size: "50"))
        .to_return(status: 200, body: response.to_json)
    end

    it "returns a list of Business Centers" do
      result = business_center.list
      expect(result).to eq(response["data"]["list"])
    end
  end

  describe "#list_all" do
    let(:page1) do
      {
        "code" => 0,
        "message" => "OK",
        "data" => {
          "list" => [{"bc_info" => {"bc_id" => "1", "name" => "BC 1"}}],
          "page_info" => {"total_number" => 2, "page" => 1, "page_size" => 1, "total_page" => 2}
        }
      }
    end

    let(:page2) do
      {
        "code" => 0,
        "message" => "OK",
        "data" => {
          "list" => [{"bc_info" => {"bc_id" => "2", "name" => "BC 2"}}],
          "page_info" => {"total_number" => 2, "page" => 2, "page_size" => 1, "total_page" => 2}
        }
      }
    end

    before do
      stub_request(:get, "#{client.config.api_base_url}v1.3/bc/get/")
        .with(query: hash_including(page: "1"))
        .to_return(status: 200, body: page1.to_json)
      stub_request(:get, "#{client.config.api_base_url}v1.3/bc/get/")
        .with(query: hash_including(page: "2"))
        .to_return(status: 200, body: page2.to_json)
    end

    it "paginates through every Business Center" do
      result = business_center.list_all(page_size: 1)
      expect(result.map { |bc| bc.dig("bc_info", "bc_id") }).to eq(%w[1 2])
    end
  end

  describe "#advertisers" do
    let(:response) do
      {
        "code" => 0,
        "message" => "OK",
        "data" => {
          "list" => [
            {"asset_id" => "111", "asset_name" => "Advertiser 1", "asset_type" => "ADVERTISER"},
            {"asset_id" => "222", "asset_name" => "Advertiser 2", "asset_type" => "ADVERTISER"}
          ],
          "page_info" => {
            "total_number" => 2,
            "page" => 1,
            "page_size" => 50,
            "total_page" => 1
          }
        }
      }
    end

    before do
      stub_request(:get, "#{client.config.api_base_url}v1.3/bc/asset/get/")
        .with(query: hash_including(bc_id: bc_id, asset_type: "ADVERTISER", page: "1", page_size: "50"))
        .to_return(status: 200, body: response.to_json)
    end

    it "returns advertiser assets the token can access via bc/asset/get (member view)" do
      result = business_center.advertisers(bc_id: bc_id)
      expect(result).to eq(response["data"]["list"])
    end

    it "uses the admin view when admin is true" do
      stub_request(:get, "#{client.config.api_base_url}v1.3/bc/asset/admin/get/")
        .with(query: hash_including(bc_id: bc_id, asset_type: "ADVERTISER"))
        .to_return(status: 200, body: response.to_json)

      result = business_center.advertisers(bc_id: bc_id, admin: true)
      expect(result).to eq(response["data"]["list"])
    end
  end

  describe "#assets" do
    let(:response) do
      {
        "code" => 0,
        "message" => "OK",
        "data" => {
          "list" => [{"asset_id" => "333", "asset_name" => "Catalog 1", "asset_type" => "CATALOG"}],
          "page_info" => {"total_number" => 1, "page" => 1, "page_size" => 50, "total_page" => 1}
        }
      }
    end

    before do
      stub_request(:get, "#{client.config.api_base_url}v1.3/bc/asset/get/")
        .with(query: hash_including(bc_id: bc_id, asset_type: "CATALOG"))
        .to_return(status: 200, body: response.to_json)
    end

    it "returns assets of the requested type" do
      result = business_center.assets(bc_id: bc_id, asset_type: "CATALOG")
      expect(result).to eq(response["data"]["list"])
    end
  end
end
