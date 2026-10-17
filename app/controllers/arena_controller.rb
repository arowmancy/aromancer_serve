class ArenaController < ApplicationController
  before_action :set_chapter, only: %i[ update ]

  def index
    render json: @api_player.current_game_json
  end

  def update
    writable = Writable.find_by(uuid: params[:id], player_legend_id: PlayerLegend.where(player: @api_player).pluck(:id))
    if writable.present?
      writable_option = writable.writable_options.find_by(uuid: params[:option_uuid])

      if writable_option.present?
        # todo: check for success
        writable_option.write!
      else
        writable.write!
      end

      render json: @api_player.current_game_json
      return
    else
      # {code: 404, name: :not_found}
      respond_with_error :not_found, I18n.t("errors.missing_writable")
    end
  end

  private

  def set_chapter
    @chapter = @api_player&.active_legend.current
    if @chapter.nil? || @chapter.turn_player != @api_player
      error_message = I18n.t("errors.not_your_turn")
      # {code: 403, name: :forbidden}
      respond_with_error :forbidden, error_message, error_message, action_name.to_sym == :create ? Arena::CREATE_PAYLOAD.dup : Arena::UPDATE_PAYLOAD.dup
      return
    end
  end
end
