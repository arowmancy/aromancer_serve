class PlayersController < ApplicationController

  def update
    if @api_player.update(player_params)
      render json: @api_player
    else
      render json: @api_player.errors, status: :unprocessable_content
    end
  end

  private
    def player_params
      params.expect(player: [ :alias, :status, :active_legend_id ])
    end
end
