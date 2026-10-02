class LegendsController < ApplicationController

  def stream
    render json: {stream: @api_player.active_legend.current.entries}
  end


  def index
    @legends = @api_player.legends

    render json: @legends, status: :ok
  end

  def create
    @legend = Legend.new(legend_params)
    if @legend.save
      render json: @legend, status: :created
    else
      respond_with_error(unprocessable_content, @legend.errors.full_messages, object = nil, param_structure = nil)
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
