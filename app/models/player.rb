class Player < ApplicationRecord
  has_many :player_legends
  has_many :legends, through: :player_legends
  has_many :legend_wins, class_name: :Legend, foreign_key: :winner_id
  has_many :story_wins, class_name: :Story, foreign_key: :winner_id
  has_many :words
  belongs_to :active_legend, class_name: :Legend, optional: true, foreign_key: :active_legend_id

  after_validation :check_active_legend
  before_create :set_api_key, :check_alias
  before_save :check_alias
  after_save :check_ready

  enum :status, [
    :gone,
    :lobby,
    :playing,
  ]

  def current_game_json
    return nil unless active_legend.present?
    active_legend.current.current_state_json(self)
  end

  private

  def spawn_bot(active_legend)
    bot = Player.create(type: BotPlayer, active_legend: active_legend)
    bot.update(alias: "bot#{bot.id}", status: :playing)
    bot
  end

  def set_api_key
    self.api_key = Random.uuid
  end

  def check_alias
    if self.alias == :guest.to_s
      self.alias = "guest#{id}"
    end
  end

  def check_active_legend
    self.active_legend_id = nil if active_legend_id == 0 ||
      active_legend_id == :null.to_s

    self.active_legend_id = self.active_legend_id.to_i if self.active_legend_id.kind_of?(String)
  end

  def check_ready
    if active_legend.present?
      player_legends.create(legend: active_legend) unless player_legends.where(player: self, legend: self.active_legend).any?

      if active_legend.player_count == 1 &&
        active_legend.player_legends.count == 1
        spawn_bot(active_legend)
      end

      if active_legend.created? &&
        active_legend.active_players.count >= 2
        active_legend.started!
      end
    end
  end
end
