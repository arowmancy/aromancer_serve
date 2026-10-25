class PlayersController < ApplicationController

  def index
    # todo: add more filtering/scopeing
    # return all other players not in :playing status
    render json: Player.where.not(id: @api_player.id, status: :playing)
  end

  def update
    # get active legend before updating player
    al = @api_player.active_legend

    # update player
    if @api_player.update(player_params)
      @api_player.reload

      # broadcast to other players if player is not playing
      if al.present? &&
        al.started? &&
        !@api_player.playing?

        al.paused!
        al.players.where.not(id: @api_player.id).each{|p|
          PlayerChannel.broadcast_to(p, {type: :arena, id: al.id})
        }
      elsif @api_player.playing? &&
        @api_player.active_legend.present?
        @api_player.active_legend.paused? &&
        @api_player.active_legend.players.where(status: :playing).count == 2

        # unpaused if needed
        @api_player.active_legend.started!
        @api_player.active_legend.players.where.not(id: @api_player.id).each{|p|
          PlayerChannel.broadcast_to(p, {type: :arena, id: @api_player.active_legend_id})
        }
      end

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
