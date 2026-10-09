module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :player

    def connect
      set_player || reject_unauthorized_connection
    end

    private
      def set_player
        @api_player = Player.find_by(api_key: request.headers["Authorization"].gsub("Bearer", "").strip)
        self.player = @api_player
        @api_player
      end
  end
end
