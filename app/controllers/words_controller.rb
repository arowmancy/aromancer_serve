class WordsController < ApplicationController
  before_action :set_legend, :set_word

  def possibilities
    render json: @word.possibilities(@api_player), status: :ok
  end

  private
    def set_legend
      @legend = Legend.find(params.expect(:legend_id))
    end

    def set_word
      @word = @legend.current.story.dictionary.words.find_by(id: params.expect(:id))
    end
end
