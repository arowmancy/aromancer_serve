require 'rails_helper'

RSpec.describe "the ino arena api" do
  HEADERS =  { "CONTENT_TYPE" => "application/json" }
  LEGEND_CREATE_PARAMS = {legend: {player_count: 2, story_count: 1}}

  it "can create and authenticate 2 players" do
    # needs to be in the first test. before blocks not working (runs too often and not as expected?)
    DatabaseCleaner.clean

    # todo: this is not actual authentication yet

    post "/players", params: JSON.unparse({player: {alias: :p1}}), headers: HEADERS
    # p1_response = response
    post "/players", params: JSON.unparse({player: {alias: :p2}}), headers: HEADERS
    # p2_response = response

    p1 = Player.first
    p2 = Player.second
    expect(p1.alias).to include("p1")
    expect(p2.alias).to include("p2")
    expect(Player.count).to eq(2)
  end

  it "can create a new legend" do
    DatabaseCleaner.clean
    p1 = Player.first
    p2 = Player.second

    # put the players in the lobby
    put_request_player_status(p1, :lobby)
    put_request_player_status(p2, :lobby)

    # pick random for which player creates the game via api
    api_key_param = "?api_key=#{[p1, p2].sample.api_key}"
    post "/legends#{api_key_param}", params: JSON.unparse(LEGEND_CREATE_PARAMS), headers: HEADERS

    expect(Legend.count).to eq(1)
  end

  it "can start the legend when both players are present" do
    DatabaseCleaner.clean
    legend = Legend.first
    p1 = Player.first
    p2 = Player.second

    # ensure legend is in the expected status
    expect(legend.created?).to be(true)
    expect(p1.lobby?).to be(true)
    expect(p2.lobby?).to be(true)

    # both players join the game
    put_request_player_status(p1, :playing, legend.id)
    expect(legend.reload.started?).to be(false)
    put_request_player_status(p2, :playing, legend.id)
    expect(legend.reload.started?).to be(true)

    expect(p1.reload.playing?).to be(true)
    expect(p2.reload.playing?).to be(true)
    expect(p1.active_legend.id).to eq(legend.id)
    expect(p2.active_legend.id).to eq(legend.id)
    expect(legend.started?).to be(true)
    expect(legend.current.present?).to be(true)

    get "/legends/#{legend.id}/arena?api_key=#{[p1, p2].sample.api_key}", headers: HEADERS
    expect(response.status).to eq(200)
    # the legend has begun
  end

  it "can display the arena correctly to players" do
    DatabaseCleaner.clean

    p1 = Player.first
    p2 = Player.second
    legend = Legend.first

    get "/legends/#{legend.id}/arena?api_key=#{p1.api_key}"
    expect(response.status).to eq(200)
    p1_response = JSON.parse(response.body)

    get "/legends/#{legend.id}/arena?api_key=#{p2.api_key}"
    expect(response.status).to eq(200)
    p2_response = JSON.parse(response.body)

    expect(p1_response[:player.to_s][:id.to_s]).to eq(p1.id)
    expect(p2_response[:player.to_s][:id.to_s]).to eq(p2.id)

    while legend.reload.current.present?
      tp = legend.current.turn_player

      params = {
        word_id: legend.current.player_words.where(player: tp).first.word_id
      }
      post "/legends/#{legend.id}/arena?api_key=#{tp.api_key}", params: JSON.unparse(params), headers: HEADERS
      post_response = JSON.parse(response.body)
      expect(response.status).to eq(200)

      puts post_response[:scroll_words.to_s]
      puts legend.current.nzindex_number
    end
  end

  def put_request_player_status(player, status = :none, active_legend_id = nil)
    return if player.nil?
    params = {player: {id: player.id, status: status, active_legend_id: active_legend_id}}
    put "/players/#{player.id}?api_key=#{player.api_key}", params: JSON.unparse(params), headers: HEADERS
  end
end
