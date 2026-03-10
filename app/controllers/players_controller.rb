class PlayersController < ApplicationController
  before_action :load_api_player, except: %i[ create ]
  before_action :set_player, only: %i[ show update ]

  # GET /players
  def index
    @players = Player.all

    render json: @players
  end

  # GET /players/1
  def show
    render json: @player
  end

  # POST /players
  def create
    @player = Player.new(player_params)

    if @player.save
      @player.reload
      render json: @player, status: :created, location: @player
    else
      render json: @player.errors, status: :unprocessable_content
    end
  end

  # PATCH/PUT /players/1
  def update
    if @player.update(player_params)
      render json: @player
    else
      render json: @player.errors, status: :unprocessable_content
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_player
      @player = Player.find(params.expect(:id))
      head :not_found unless @player == @api_player
    end

    # Only allow a list of trusted parameters through.
    def player_params
      params.expect(player: [ :alias, :status, :active_legend_id ])
    end
end
