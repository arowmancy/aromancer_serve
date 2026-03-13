class ArenaController < ApplicationController
  before_action :load_api_player
  before_action :set_legend, only: %i[ index ]

  def index
    render json: @api_player.current_game_json
  end

  def create
    params.permit!
    if @api_player.active_legend&.current&.turn_player == @api_player
      words = @api_player.active_legend.current.story.dictionary.words
      word = words.find_by(id: params[:arena][:word_id]);
      if word.present?
        if params[:arena][:sentence].present?
          psentence = params[:arena][:sentence]
          sws = @api_player.active_legend.current.story.dictionary.words.where(id: psentence[:words].map{|w| w[:id]})
          @api_player.submit_turn(word, sws, psentence[:signature_id].present?)
        else
          @api_player.submit_turn(word)
        end
      else
        head :not_found
      end
    end

    render json: @api_player.current_game_json
  end

  private

  def set_legend
    @legend = Legend.find(params.expect(:legend_id))
  end
end
