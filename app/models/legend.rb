class Legend < ApplicationRecord
  MIN_STORY_COUNT = 1
  MIN_PLAYERS = 2
  MAX_PLAYERS = 3

  has_many :player_legends
  has_many :players, through: :player_legends
  has_many :stories
  belongs_to :winner, class_name: :Player, optional: true, foreign_key: :winner_id

  # before_validation :set_defaults
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

  def set_defaults
    story_count = MIN_STORY_COUNT if story_count.nil?
    player_count = MIN_PLAYERS if player_count.nil?
  end

  def configure_state
    case status.to_sym
    when :created
      stories.create unless stories.any?
    # when todo...
    else
    end
  end
end
