class ArenaController < ApplicationController
  before_action :load_api_player
  before_action :set_legend, only: %i[ index ]

  PAYLOAD_STRUCTURE = {
    arena: {
      word_id: :integer, # this is the "card being played" this turn
      sentence: {
        signature_id: :integer, # nullable, if not present, attempt to create open sentence
        words: [{
          id: :integer # (allowed >=0) id to words table record
        }]
      }
    }
  }

  def index
    render json: @api_player.current_game_json
  end

  def create
    params.permit!

    # not current player
    if @api_player.active_legend&.current&.turn_player != @api_player
      error_message = "it is not your turn"
      # {code: 403, name: :forbidden}
      respond_with_error :forbidden, error_message
      return
    end

    arena = params[:arena]

    if arena.nil?
      # missing params
      error_message = "missing arena param"
      # {code: 400, name: :bad_request}
      respond_with_error :bad_request, error_message
      return
    end


    word = Word.find_by(id: arena[:word_id])
    if word.nil?
      error_message = "invalid word_id param"
      # {code: 400, name: :bad_request}
      respond_with_error :bad_request, error_message
      return
    end

    sws = []
    sentence = nil
    should_sign = false
    sentence_id = nil
    if arena[:sentence].present?
      sentence = arena[:sentence]
      sentence_id = sentence[:id]
      sentence_words = sentence[:words]

      # ensure
      should_sign = sentence[:signature_id].present?

      if sentence_words.present? &&
        sentence_words.kind_of?(Array) &&
        sentence_words.any?

        # ensure all payload sentence scroll words are
        # in the current story's dictionary words.
        sws = @api_player.active_legend.current.story.dictionary.words.where(
          id: sentence_words.map{|w| w[:id]}
        )
        if sws.count != sentence_words.count
          error_message = "sentence words array is present but contains invalid word ids(s)"
          # {code: 400, name: :bad_request}
          respond_with_error :bad_request, error_message, sentence_words
          return
        end
      end
    end

    # if we make it here, the payload is ready to be validated for submission
    @api_player.submit_turn(word, sentence_id, sws, should_sign)
    render json: @api_player.current_game_json
  end

  private

  def respond_with_error(head_response, message, object = nil)
    # using Rack::Utils::SYMBOL_TO_STATUS_CODE to set head status code

    Rails.logger.debug(message)
    render json: {
      error_message: message,
      error_object: object,
      param_structure: ArenaController::PAYLOAD_STRUCTURE
    }, status: head_response
  end

  def set_legend
    @legend = Legend.find(params.expect(:legend_id))
  end
end
