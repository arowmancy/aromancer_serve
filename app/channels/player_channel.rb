class PlayerChannel < ApplicationCable::Channel
  def subscribed
    stream_for self.connection.player
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end

