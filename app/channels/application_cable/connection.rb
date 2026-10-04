module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :player

    def connect
      set_player || reject_unauthorized_connection
    end

    private
      def set_player
        self.player = Player.find_by(api_key: request.params[:api_key])
        @api_player = self.player
      end
  end
end
