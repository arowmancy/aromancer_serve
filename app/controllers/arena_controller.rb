class ArenaController < ApplicationController
  before_action :load_api_player
  before_action :set_legend, only: %i[ index ]
  def index
    render json: @api_player.current_game_json
  end

  private

  def set_legend
    @legend = Legend.find(params.expect(:legend_id))
  end
end
