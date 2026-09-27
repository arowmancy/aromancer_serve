class ArenaController < ApplicationController
  before_action :set_chapter, only: %i[ create update ]

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
    @param_structure = ArenaController::UPDATE_PAYLOAD
    params.permit!
    arena = params[:arena]

    if arena.nil?
      # missing params
      error_message = "missing arena param"
      # {code: 400, name: :bad_request}
      respond_with_error :bad_request, error_message
      return
    end

    sentence_ids = arena[:sentence_ids]
    if !sentence_ids.kind_of?(Array) ||
      sentence_ids.count <= 1
      # need at least 2 valid open sentences to continue
      error_message = "invalid :sentence_ids configuration: #{sentence_ids}"
      # {code: 400, name: :bad_request}
      respond_with_error :bad_request, error_message
      return
    end

    to_combine = @chapter.unsigned_sentences.where(id: sentence_ids)
    if to_combine.count != sentence_ids.count
      error_message = "missing open sentences for sentence ids: #{sentence_ids}."
      # {code: 400, name: :bad_request}
      respond_with_error :bad_request, error_message
      return
    end

    sigs = @chapter.story.dictionary.words.where(id: @chapter.player_words.pluck(:word_id)).where(value: arena[:value])
    if sigs.empty?
      # player must be able to sign the resultant sentence
      error_message = "player cannot sign the new sentence of value #{arena[:value]}."
      # {code: 400, name: :bad_request}
      respond_with_error :bad_request, error_message
      return
    end

    # get all word ids from sentence_ids
    word_ids = to_combine.map{|s| s.words.pluck(:id)}.flatten
    words = @chapter.story.dictionary.words.where(id: word_ids)
    if words.count != word_ids.count
      error_message = "unexpected sentence word ids: #{word_ids}."
      # {code: 400, name: :bad_request}
      respond_with_error :bad_request, error_message
      return
    end

    # create new sentence with params
    sentence = @chapter.sentences.create(
      author: @api_player,
      value: arena[:value],
      is_stack: arena[:is_stack],
    )
    unless sentence.present? && sentence.persisted?
      error_message = "error creating new sentence: #{sentence.errors.full_messages}."
      # {code: 400, name: :bad_request}
      respond_with_error :bad_request, error_message
      return
    end

    # delete sentence_ids
    @chapter.sentences.where(id: sentence_ids).destroy_all

    # attach all of the words
    words.each{|w|
      sentence.sentence_words.create(word: w)
    }

    render json: @api_player.current_game_json
  end

  def create
    params.permit!
    arena = params[:arena]

    if arena.nil?
      # missing params
      error_message = "missing arena param"
      # {code: 400, name: :bad_request}
      respond_with_error :bad_request, error_message
      return
    end

    word = nil
    if arena[:word_id].present?
      word = @chapter.story.dictionary.words.find_by(id: arena[:word_id])
    end

    existing_sentence = nil
    if word.nil?
      existing_sentence = @chapter.sentences.find_by(id: arena[:sentence_id])
    end

    # debugger

    if word.nil? && existing_sentence.nil?
      error_message = "invalid value(s) at param [word_id or sentence_id]"
      # {code: 400, name: :bad_request}
      respond_with_error :bad_request, error_message
      return
    end

    sws = []
    sentence = nil
    should_sign = false
    is_stack = false
    if arena[:sentence].present?
      sentence = arena[:sentence]
      word_ids = sentence[:word_ids] || existing_sentence&.words.pluck(:id)

      should_sign = sentence[:signature_id].present?

      is_stack = sentence[:is_stack]
      if word_ids.present? &&
        word_ids.kind_of?(Array) &&
        word_ids.any?

        # ensure all payload sentence scroll words are
        # in the current story's dictionary words.
        sws = @chapter.story.dictionary.words.where(
          id: word_ids
        )
        # if sws.count != word_ids.count
        #   error_message = "sentence words array is present but contains invalid word ids(s)"
        #   # {code: 400, name: :bad_request}
        #   respond_with_error :bad_request, error_message, word_ids
        #   return
        # end
      end
    end

    if word.nil?
      if should_sign
        word = @chapter.story.dictionary.words.find_by(
          id: sentence[:signature_id]
        )
      else
        # expect the player's word to be in the payload sentence words
        word = sws.find_by(id: @chapter.player_words.where(player: @api_player).pluck(:word_id))
        if word.nil?
          word = sws.find_by(id: @chapter.scroll_words.pluck(:word_id))
        end

        if word.nil?
          error_message = "unable to find word when modifying a sentence"
          # {code: 400, name: :bad_request}
          respond_with_error :bad_request, error_message
          return
        end
      end
    end

    # if we make it here, the payload is ready to be submitted
    @new_entry = @chapter.entries.create(
      player: @api_player,
      word: word,
      description: "#{@api_player.alias} wytyd: #{arena[:wytyd]}"
    )
    @api_player.submit_turn(word, existing_sentence&.id, sws, should_sign, is_stack, entry: @new_entry)
    render json: @api_player.current_game_json, status: :created
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
