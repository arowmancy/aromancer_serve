class PlayerLegend < ApplicationRecord
  belongs_to :player
  belongs_to :legend

  after_create :notify_player

  private

  def notify_player
    return if player.kind_of?(BotPlayer)
    PlayerChannel.broadcast_to(player, {type: :legends})
  end
end
