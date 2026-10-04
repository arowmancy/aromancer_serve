class Legend < ApplicationRecord
  MIN_STORY_COUNT = 1
  MIN_PLAYERS = 1
  MAX_PLAYERS = 2

  has_many :active_players, class_name: :Player, foreign_key: :active_legend_id
  has_many :player_legends
  has_many :players, through: :player_legends
  has_many :stories
  belongs_to :winner, class_name: :Player, optional: true, foreign_key: :winner_id

  validates :story_count, numericality: { greater_than: Legend::MIN_STORY_COUNT - 1 }
  validates :player_count, numericality: { in: Legend::MIN_PLAYERS..Legend::MAX_PLAYERS }

  enum :status, [
    :created,
    :started,
    :paused,
    :dnf,
    :complete,
  ]

  def waiting_room
    {
      title: "waiting for players",
      players: active_players.map{|p| {id: p.id, alias: p.alias}}
    }
  end

  def current
    c = (
      stories.select{|s|
        s.chapters.where(is_final: false).any?
      }.first || stories.last
    )&.current_chapter

    if c.nil?
      return start
    end

    return c
  end

  def start
    return unless active_players.count > 0

    if stories.count < story_count
      if stories.count == 0
        # player setup
        active_players.each{|p|
          player_legends.create(player: p) unless player_legends.where(player: p).any?
        }

        if player_count == 1 &&
          player_legends.count == 1
          bot = Player.spawn_bot(self)
          player_legends.create(player: bot)
        end

        started! if created? && active_players.count == 2
      end

      return nil unless started?
      reload

      # stories++
      next_story = stories.create(dealer: active_players.where.not(id: stories&.last&.dealer_id).first || active_players.first)
      next_story.save
      next_story.start

      return next_story.chapters.first
    else
      stories.last.finalize
      complete!

      active_players.each{|p|
        PlayerChannel.broadcast_to(p, {type: :arena, id: self.id})
      }

      return stories.last.chapters.last
    end
  end
end
