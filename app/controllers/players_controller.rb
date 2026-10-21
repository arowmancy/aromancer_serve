class PlayersController < ApplicationController

  def index
    # todo: add more filtering/scoping
    # return all other players not in :playing status
    render json: Player.where.not(id: @api_player.id, status: :playing)
  end

  def update
    # get active legend before updating player
    # al_id = @api_player.active_legend&.id
    # previous_al = Legend.find_by(id: al_id)

    # update player
    if @api_player.update(player_params)
      # @api_player.reload
      # @api_player.active_legend&.reload
      # previous_al&.reload
      # if !@api_player.active_legend.present? &&
      #   previous_al.present? &&
      #   previous_al.started? &&
      #   previous_al.active_players.count < 2 &&
      #   !@api_player.playing?

      #   # broadcast to other players if player is not playing
      #   previous_al.paused!
      #   previous_al.players.where.not(id: @api_player.id).each{|p|
      #     PlayerChannel.broadcast_to(p, {type: :arena, id: previous_al.id})
      #   }
      # elsif previous_al.nil? &&
      #   @api_player.playing? &&
      #   @api_player.active_legend.present?
      #   @api_player.active_legend.paused? &&
      #   @api_player.active_legend.active_players.count == 2

      #   # unpaused if needed
      #   @api_player.active_legend.current
      #   @api_player.active_legend.started!
      #   @api_player.active_legend.players.where.not(id: @api_player.id).each{|p|
      #     PlayerChannel.broadcast_to(p, {type: :arena, id: @api_player.active_legend_id})
      #   }
      # end

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
