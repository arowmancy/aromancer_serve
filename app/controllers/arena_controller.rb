class ArenaController < ApplicationController
  include Arena
  before_action :set_chapter, only: %i[ create update ]

  def index
    render json: @api_player.current_game_json
  end

  def update
    params.permit!
    arena = params[:arena]
    process_arena_update(arena, @chapter, @api_player)

    render json: @api_player.reload.current_game_json
  end

  def create
    params.permit!
    arena = params[:arena]

    process_arena_create(arena, @chapter, @api_player)

    render json: @api_player.reload.current_game_json, status: :created
  end

  private

  def set_chapter
    @chapter = @api_player&.active_legend.current
    if @chapter.nil? || @chapter.turn_player != @api_player
      error_message = "it is not your turn"
      # {code: 403, name: :forbidden}
      respond_with_error :forbidden, error_message
      return
    end
  end
end
