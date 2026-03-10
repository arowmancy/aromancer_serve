class ApplicationController < ActionController::API

  private

  def load_api_player
    @api_player = Player.find_by(api_key: params[:api_key])
    head :not_found unless @api_player.present?
  end
end
