class Story < ApplicationRecord
  belongs_to :legend
  belongs_to :winner, class_name: :Player, optional: true, foreign_key: :winner_id
  has_many :chapters
  has_one :dictionary

  def start
    dictionary = Dictionary.create(story: self)
    # todo: alternate when multiple stories implemented
    dealer = legend.players.first
    # puts legend.players
    # puts dealer
    # puts legend.players.where.not(id: dealer.id).first
    chapter = chapters.create(
      dealer: dealer,
      turn_player: legend.players.where.not(id: dealer.id).first
    )
    chapter.start
  end

  def current_chapter
    @current_chapter ||= chapters.to_a.filter{|c| c.player_words.count > 0}.first
  end
end


# a "story":
# one full pass through the full tarot deck broken down by chapters.
# players are dealt the same number of cards in each chapter.
#
# 2 players:
#
#   2 players x 11 cards/each x 3 chapters = 66 cards
#   2x11x3=(66) cards each (3 chapters)
#
#   2 players x 6 cards/each x 1 chapter = 12 cards
#   2x6x1 =(12) cards each (1 chapter)
# total: 78 = 66+12
#
# a standard 2-player story has 4 chapters.

# 3 players:
#   the story will consist of the following:
#
#   3 players x 11 cards/each x 2 chapters = 66 cards
#   3x11x2=(66) cards each (2 chapters)
#
#   3 players x 4 cards/each x 1 chapter = 12 cards
#   3x4x1 =(12) cards each (1 chapter)
# total: 78 = 66+12
#
# a standard 3-player story has 3 chapters.