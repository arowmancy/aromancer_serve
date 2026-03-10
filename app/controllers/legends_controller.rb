class LegendsController < ApplicationController
  before_action :load_api_player
  before_action :set_legend, only: %i[ show update ]

  # GET /legends
  def index
    @legends = Legend.all

    render json: @legends
  end

  # GET /legends/1
  def show
    render json: @legend
  end

  # POST /legends
  def create
    @legend = Legend.new(legend_params)

    if @legend.save
      render json: @legend, status: :created, location: @legend
    else
      render json: @legend.errors, status: :unprocessable_content
    end
  end

  # PATCH/PUT /legends/1
  def update
    if @legend.update(legend_params)
      render json: @legend
    else
      render json: @legend.errors, status: :unprocessable_content
    end
  end

  private
    def set_legend
      @legend = Legend.find(params.expect(:id))
    end

    def legend_params
      params.expect(legend: [ :status, :story_count, :player_count ])
    end
end
