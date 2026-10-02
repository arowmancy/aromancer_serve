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
    api_key_param = "?api_key=#{[p1, p2].sample.api_key}"
    post "/legends#{api_key_param}", params: LEGEND_CREATE_PARAMS.to_json, headers: HEADERS
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

    get "/legends/#{legend.id}/arena?api_key=#{[p1, p2].sample.api_key}", headers: HEADERS
    expect(response.status).to eq(200)
    expect(legend.reload.started?).to be(true)
  end

  it "can play through a game" do
    legend = Legend.last
    expect(legend.started?).to be(true)
    p1 = Player.find_by(alias: :p1)
    p2 = Player.find_by(alias: :p2)
    d = legend.current.story.dictionary


    get "/legends/#{legend.id}/arena?api_key=#{p1.api_key}"
    expect(response.status).to eq(200)
    p1_response = JSON.parse(response.body)

    get "/legends/#{legend.id}/arena?api_key=#{p2.api_key}"
    expect(response.status).to eq(200)
    p2_response = JSON.parse(response.body)

    expect(p1_response[:player.to_s][:id.to_s]).to eq(p1.id)
    expect(p2_response[:player.to_s][:id.to_s]).to eq(p2.id)

    chapter = 0
    turn_count = 0
    turn_map = [
      { #p2
        words: d.get_word(:t1)
      },
      { #p1
        words: d.get_word(:t2)
      },
      { #p2
        words: d.get_word(:t4)
      },
      [ #p1
        {
          action: :combine,
          words: [d.get_word(:t1), d.get_word(:t2)]
        },
        {
          words: d.get_word(:t5)
        }
      ]
    ]
    while legend.reload.current.present? && legend.reload.started?
      if legend.current.nzindex_number > chapter
        chapter = legend.current.nzindex_number
        # puts "\tchapter #{chapter}"
      end

      play_turn(turn_count < turn_map.length ? turn_map[turn_count] : nil, legend, p1, p2)
      turn_count += 1
    end

    # puts JSON.pretty_generate legend.current.current_state_json(p1)
    # puts JSON.pretty_generate legend.current.current_state_json(p2)
  end

  def play_turn(turns, legend, p1, p2)
    turns = [turns] unless turns.kind_of?(Array)
    tp = legend.current.turn_player
    url = "/legends/#{legend.id}/arena?api_key=#{tp.api_key}"
    params = {word_id: legend.current.player_words.where(player: tp).first.word_id}.to_json
    turns.each{|turn|
      if turn.present?
        if turn[:action].nil?
          # default
          params = {
            word_id: turn[:words].id # expects :words to contain Word instance
          }.to_json
        else
          case turn[:action]
          when :combine
            params = {
              word_id: turn[:words][1].id, # not abstract at all
              sentence: {
                word_ids: turn[:words].map{|w| w.id} # expects :words to contain [Word] array
              }
            }.to_json
          when :sign
            params = {
              sentence_id: Sentence.last.id,
              sentence: {
                signature_id: turn[:words].id # expects :words to contain Word instance
              }
            }.to_json
          end
        end
      end
      # puts params
      post url, params: params, headers: HEADERS
      # post_response = JSON.parse(response.body)
      # puts post_response
      expect(response.status).to eq(201)
    }
  end

  def put_request_player_status(player, status = :none, active_legend_id = nil)
    return if player.nil?
    params = {player: {id: player.id, status: status, active_legend_id: active_legend_id}}.to_json
    put "/players/#{player.id}?api_key=#{player.api_key}", params: params, headers: HEADERS
    # puts JSON.parse response.body
  end
end
