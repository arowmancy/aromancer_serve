class Legend < ApplicationRecord
  MIN_STORY_COUNT = 1
  MIN_PLAYERS = 1
  MAX_PLAYERS = 3

  has_many :active_players, class_name: :Player, foreign_key: :active_legend_id
  has_many :player_legends
  has_many :players, through: :player_legends
  has_many :stories
  belongs_to :winner, class_name: :Player, optional: true, foreign_key: :winner_id

  after_save :configure_state

  validates :story_count, numericality: { greater_than: Legend::MIN_STORY_COUNT - 1 }
  validates :player_count, numericality: { in: Legend::MIN_PLAYERS..Legend::MAX_PLAYERS }

  enum :status, [
    :created,
    :started,
    :paused,
    :dnf,
    :complete,
  ]

  private

  def configure_state
    case status.to_sym
    when :created
      stories.create unless stories.any?
    when :started
      stories.first.start
    # ...
    else


    end
  end
end
