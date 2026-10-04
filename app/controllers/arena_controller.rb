class ArenaController < ApplicationController
  include Arena
  before_action :set_chapter, only: %i[ create update ]

  # ArenaController::CREATE_PAYLOAD
  CREATE_PAYLOAD = {
    arena: {
      wytyd: "what you think you're doing. included in audit trail.",
      word_id: "integer, this is the 'word being played' this turn",
      sentence_id: "integer, this is the 'sentence being played' this turn (optional)",
      sentence: {
        signature_id: "integer, nullable, if present, attempt to sign the sentence.",
        word_ids: "integer array, word ids to include in sentence.",
        is_stack: "boolean, is_stack for new sentence.",
      }
    }
  }

  # ArenaController::UPDATE_PAYLOAD
  UPDATE_PAYLOAD = {
    arena: {
      wytyd: "what you think you're doing. included in audit trail.",
      sentence_ids: "integer array, sentence ids to combine",
      value: "integer, value of the new sentence.",
      is_stack: "boolean, is_stack for new sentence."
    }
  }

  def index
    render json: @api_player.current_game_json
  end

  # this is used for combining sentences into one
  # it does not count as the player's turn so long
  # as they are holding a valid signature card.
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
