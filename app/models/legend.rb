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

  def current
    c = (
      stories.select{|s|
        s.chapters.where(is_final: false).any?
      }.first || stories.last
    )&.current_chapter

    if c.nil?
      return check_end_of_story
    end

    return c
  end

  def check_end_of_story
    last_story = stories.last
    return unless last_story.chapters.where(is_final: true).empty?

    last_story.finalize
    if stories.count < story_count
      # stories++
      next_story = stories.create
      next_story.start
      next_story.save

      return next_story.chapters.first
    else
      # todo: winner/stats
      complete!
    end
  end

  private

  def configure_state
    case status.to_sym
    when :created
      stories.create unless stories.any?
    when :started
      stories.first.start
    when :complete
      # todo:
    else

    end
  end
end
