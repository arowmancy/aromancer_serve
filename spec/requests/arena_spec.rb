require 'rails_helper'

RSpec.describe "the aromancer arena api" do
  HEADERS =  { "Content-Type" => "application/json" }
  LEGEND_CREATE_PARAMS = {legend: {player_count: 2, story_count: 1, status: :created}}

  it "can create and authenticate 2 players" do
    # todo: this is not actual authentication yet

    post(
      "/users",
      params: {user: {email_address: :p1, password: :p, password_confirmation: :p}}.to_json,
      headers: HEADERS
    ) unless User.find_by(email_address: :p1).present?
    # p1_response = response
    post(
      "/users",
      params: {user: {email_address: :p2, password: :p, password_confirmation: :p}}.to_json,
      headers: HEADERS
    ) unless User.find_by(email_address: :p2).present?
    # p2_response = response

    p1 = Player.find_by(alias: :p1)
    p2 = Player.find_by(alias: :p2)
    expect(p1.alias).to include("p1")
    expect(p2.alias).to include("p2")
    expect(Player.count).to eq(2)
  end

  it "can create a new legend" do
    p1 = Player.find_by(alias: :p1)
    p2 = Player.find_by(alias: :p2)

    # put the players in the lobby
    put_request_player_status(p1, :lobby)
    put_request_player_status(p2, :lobby)

    # pick random for which player creates the game via api
    lc = Legend.count
    api_key_param = "Bearer #{[p1, p2].sample.api_key}"
    post "/legends", params: LEGEND_CREATE_PARAMS.to_json, headers: HEADERS.merge({"Authorization": api_key_param})
    expect(Legend.count).to eq(lc + 1)
  end

  it "can start the legend when both players are present" do
    legend = Legend.last
    p1 = Player.find_by(alias: :p1)
    p2 = Player.find_by(alias: :p2)

    # ensure legend is in the expected status
    expect(legend.created?).to be(true)
    expect(p1.lobby?).to be(true)
    expect(p2.lobby?).to be(true)

    # both players join the game
    put_request_player_status(p1, :playing, legend.id)
    put_request_player_status(p2, :playing, legend.id)
    sleep(0.1)
    expect(legend.reload.started?).to be(false)
    expect(p1.reload.playing?).to be(true)
    expect(p2.reload.playing?).to be(true)
    expect(p1.active_legend.id).to eq(legend.id)
    expect(p2.active_legend.id).to eq(legend.id)
    expect(legend.current.present?).to be(true)

    api_key_param = "Bearer #{[p1, p2].sample.api_key}"
    get "/legends/#{legend.id}/arena", headers: HEADERS.merge({"Authorization": api_key_param})
    expect(response.status).to eq(200)
    expect(legend.reload.started?).to be(true)
  end

  it "can play through a game" do
    legend = Legend.last
    expect(legend.started?).to be(true)
    p1 = Player.find_by(alias: :p1)
    p2 = Player.find_by(alias: :p2)
    d = legend.current.story.dictionary

    api_key_param = "Bearer #{p1.api_key}"
    get "/legends/#{legend.id}/arena", headers: HEADERS.merge({"Authorization": api_key_param})
    expect(response.status).to eq(200)
    p1_response = JSON.parse(response.body)

    api_key_param = "Bearer #{p2.api_key}"
    get "/legends/#{legend.id}/arena", headers: HEADERS.merge({"Authorization": api_key_param})
    expect(response.status).to eq(200)
    p2_response = JSON.parse(response.body)

    expect(p1_response[:player.to_s][:id.to_s]).to eq(p1.id)
    expect(p2_response[:player.to_s][:id.to_s]).to eq(p2.id)

    chapter = 0
    while legend.reload.current.present? && legend.reload.started?
      if legend.current.nzindex_number > chapter
        chapter = legend.current.nzindex_number
        # puts "\tchapter #{chapter}"
      end
      play_turn(legend, p1, p2)
    end

    # puts JSON.pretty_generate p1.current_game_json
    # puts JSON.pretty_generate p2.current_game_json
    puts legend.reload.status
  end

  def play_turn(legend, p1, p2)
    tp = legend.current.turn_player
    params = {}
    wid = nil
    tp_word_ids = legend.current.player_words.where(player: tp).pluck(:word_id)
    rand(1..11).times do |i|
      wid = tp_word_ids.sample
    end

    api_key_param = "Bearer #{tp.api_key}"
    get "/legends/#{legend.id}/words/#{wid}/possibilities", headers: HEADERS.merge({"Authorization": api_key_param})
    possible = JSON.parse(response.body)
    # puts possible["word"]["humanized"]
    # puts "possible.for_type: #{possible["for_type"]}"
    # puts "possible.word: #{possible["word"]}"
    # puts "possible.options: #{possible["options"]}"
    # puts JSON.pretty_generate possible
    if possible["options"].any?
      payload = nil
      rand(1..11).times do |i|
        payload = possible["options"].sample["payload"]
      end
      parsed_payload = JSON.parse(payload)
      params = {arena: parsed_payload}
    else
      params = {arena: {word_id: wid}}
    end

    # puts params
    url = "/legends/#{legend.id}/arena"
    post url, params: params.to_json, headers: HEADERS.merge({"Authorization": api_key_param})
    # post_response = JSON.parse(response.body)
    # puts post_response
    expect(response.status).to eq(201)
  end

  def put_request_player_status(player, status = :none, active_legend_id = nil)
    return if player.nil?
    api_key_param = "Bearer #{player.api_key}"
    params = {player: {id: player.id, status: status, active_legend_id: active_legend_id}}.to_json
    put "/players/#{player.id}?api_key=#{player.api_key}", params: params, headers: HEADERS.merge({"Authorization": api_key_param})
    # puts JSON.parse response.body
  end
end
