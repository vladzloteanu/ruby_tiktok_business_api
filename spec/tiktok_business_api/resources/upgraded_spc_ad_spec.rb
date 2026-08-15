# frozen_string_literal: true

require "spec_helper"

RSpec.describe TiktokBusinessApi::Resources::UpgradedSpcAd do
  let(:client) { TiktokBusinessApi::Client.new(app_id: "test_app_id", secret: "test_secret") }
  let(:ads) { described_class.new(client) }
  let(:base) { "#{client.config.api_base_url}v1.3/smart_plus/ad" }
  let(:advertiser_id) { "7190109983210553346" }
  let(:smart_plus_ad_id) { "1873351430429714" }

  def ok(data)
    {"code" => 0, "message" => "OK", "data" => data}.to_json
  end

  describe "#list" do
    let(:ad) do
      {"smart_plus_ad_id" => smart_plus_ad_id, "adgroup_id" => "1873346976955441",
       "creative_list" => [{"ad_material_id" => "mat_1", "smart_plus_creative_id" => "crea_1"}]}
    end

    it "returns the ads" do
      stub_request(:get, "#{base}/get/").with(query: hash_including(advertiser_id: advertiser_id))
        .to_return(status: 200, body: ok("list" => [ad]))

      expect(ads.list(advertiser_id: advertiser_id)).to eq([ad])
    end

    # Ad ids here are smart_plus_ad_ids; filtering by ad_ids is silently ignored.
    it "puts campaign, ad group and ad ids inside filtering" do
      stub = stub_request(:get, "#{base}/get/")
        .with(query: hash_including(
          filtering: {campaign_ids: ["c1"], adgroup_ids: ["ag1"], smart_plus_ad_ids: ["a1"]}.to_json
        ))
        .to_return(status: 200, body: ok("list" => []))

      ads.list(advertiser_id: advertiser_id, campaign_id: "c1", adgroup_id: "ag1", smart_plus_ad_id: "a1")
      expect(stub).to have_been_requested
    end

    it "returns an empty array when the response carries no list" do
      stub_request(:get, "#{base}/get/").with(query: hash_including(advertiser_id: advertiser_id))
        .to_return(status: 200, body: ok({}))

      expect(ads.list(advertiser_id: advertiser_id)).to eq([])
    end
  end

  describe "#create" do
    it "posts advertiser_id, adgroup_id and everything else through" do
      stub = stub_request(:post, "#{base}/create/")
        .with(body: hash_including(
          "advertiser_id" => advertiser_id, "adgroup_id" => "ag1", "ad_name" => "VAR-1.cmt"
        ))
        .to_return(status: 200, body: ok("smart_plus_ad_id" => "new_ad"))

      result = ads.create(advertiser_id: advertiser_id, adgroup_id: "ag1", ad_name: "VAR-1.cmt")

      expect(stub).to have_been_requested
      expect(result).to eq("smart_plus_ad_id" => "new_ad")
    end
  end

  describe "#update" do
    it "posts smart_plus_ad_id, not ad_id" do
      stub = stub_request(:post, "#{base}/update/")
        .with(body: hash_including("advertiser_id" => advertiser_id, "smart_plus_ad_id" => smart_plus_ad_id))
        .to_return(status: 200, body: ok("smart_plus_ad_id" => smart_plus_ad_id))

      ads.update(advertiser_id: advertiser_id, smart_plus_ad_id: smart_plus_ad_id, ad_name: "renamed")
      expect(stub).to have_been_requested
    end
  end

  describe "#update_status" do
    %w[ENABLE DISABLE DELETE].each do |status|
      it "posts #{status} against a list of ad ids" do
        stub = stub_request(:post, "#{base}/status/update/")
          .with(body: {"advertiser_id" => advertiser_id,
                       "smart_plus_ad_ids" => [smart_plus_ad_id],
                       "operation_status" => status})
          .to_return(status: 200, body: ok({}))

        ads.update_status(advertiser_id: advertiser_id, smart_plus_ad_ids: [smart_plus_ad_id],
          operation_status: status)
        expect(stub).to have_been_requested
      end
    end
  end

  describe "#update_material_status" do
    # Regression: this used to send a `materials:` array, which the API does not know.
    # /smart_plus/ad/material_status/update/ takes ad_material_ids + operation_status.
    it "posts ad_material_ids and operation_status" do
      stub = stub_request(:post, "#{base}/material_status/update/")
        .with(body: {"advertiser_id" => advertiser_id,
                     "smart_plus_ad_id" => smart_plus_ad_id,
                     "ad_material_ids" => %w[mat_1 mat_2],
                     "operation_status" => "DISABLE"})
        .to_return(status: 200, body: ok("ad_material_ids" => %w[mat_1 mat_2], "material_status" => "DISABLE"))

      result = ads.update_material_status(
        advertiser_id: advertiser_id, smart_plus_ad_id: smart_plus_ad_id,
        ad_material_ids: %w[mat_1 mat_2], operation_status: "DISABLE"
      )

      expect(stub).to have_been_requested
      expect(result["material_status"]).to eq("DISABLE")
    end

    it "never sends a materials key" do
      stub = stub_request(:post, "#{base}/material_status/update/")
        .with { |req| !JSON.parse(req.body).key?("materials") }
        .to_return(status: 200, body: ok({}))

      ads.update_material_status(advertiser_id: advertiser_id, smart_plus_ad_id: smart_plus_ad_id,
        ad_material_ids: ["mat_1"], operation_status: "ENABLE")
      expect(stub).to have_been_requested
    end
  end

  describe "#get" do
    it "looks the ad up through the smart_plus_ad_ids filter" do
      stub_request(:get, "#{base}/get/")
        .with(query: hash_including(filtering: {smart_plus_ad_ids: [smart_plus_ad_id]}.to_json))
        .to_return(status: 200, body: ok("list" => [{"smart_plus_ad_id" => smart_plus_ad_id}]))

      expect(ads.get(advertiser_id: advertiser_id, smart_plus_ad_id: smart_plus_ad_id))
        .to eq("smart_plus_ad_id" => smart_plus_ad_id)
    end
  end

  it "is reachable as client.upgraded_spc_ads" do
    expect(client.upgraded_spc_ads).to be_a(described_class)
  end

  it "targets the smart_plus ad namespace" do
    expect(ads.base_path).to eq("v1.3/smart_plus/ad")
  end
end
