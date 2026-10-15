class LegendsController < ApplicationController

  def find
    legends = Legend.where(status: :created).order(created_at: :asc)
    render json: legends, status: :ok
  end

  def stream
    render json: {
      stream: @api_player.active_legend&.current.nil? ?
      [] : Entry.where(chapter_id: @api_player.active_legend.current.story.chapters.pluck(:id)).order(created_at: :asc)
    }
  end

  def index
    legends = @api_player.legends.order(created_at: :asc)
    render json: legends, status: :ok
  end

  def create
    @legend = Legend.new(legend_params)
    if @legend.save
      render json: @legend, status: :created
    else
      respond_with_error(unprocessable_content, @legend.errors.full_messages)
    end
  end

  private

    def legend_params
      params.expect(legend: [
        :status,
        :story_count,
        :player_count
      ])
    end
end
