class Story < ApplicationRecord
  belongs_to :legend
  belongs_to :winner, class_name: :Player, optional: true, foreign_key: :winner_id
  has_many :chapters
  has_one :dictionary

  TOTAL_POINTS = 11.to_f

  def start
    dictionary = Dictionary.create(story: self)

    dealer = legend.players.first

    @current_chapter = chapters.create(
      dealer: dealer,
      turn_player: legend.players.where.not(id: dealer.id).first
    )
    @current_chapter.start
  end

  def start_next_chapter
    return if chapters.where(is_final: true).present?
    dealer = legend.players.where.not(id: chapters.last.dealer_id).first
    @current_chapter = chapters.create(
      dealer: dealer,
      turn_player: legend.players.where.not(id: dealer.id).first
    )
    lc = chapters.last
    ScrollWord.where(chapter: lc).update_all(chapter_id: @current_chapter.id)
    Sentence.where(chapter: lc, signature: nil).update_all(chapter_id: @current_chapter.id)

    @current_chapter.start
    @current_chapter
  end

  def current_chapter
    @current_chapter ||= chapters.to_a.filter{|c| c.unspoken_words.any?}.first || start_next_chapter
  end

  def finalize
    # end of story
    final_chapter = chapters.last
    return unless final_chapter.present? && final_chapter.is_final

    open_sentences = final_chapter.sentences.where(signature: nil)
    return unless final_chapter.unspoken_words.any? || open_sentences.any?

    scroll_winner = final_chapter.sentences.where.not(signature: nil).order(update_at: :asc).last&.author
    if scroll_winner.nil?
      Rails.logger.debug("expected scroll_winner to be author of last signed sentence but found nothing")
      scroll_winner = legend.players.first
    end

    closing_sentence = final_chapter.sentences.create(
      is_stack: true,
      value: final_chapter.unwritten_words.map{|uw| uw.value}.max,
      words: dictionary.words.where(id: scroll_words.pluck(:word_id)),
      signature: final_chapter.scroll_words.first.word, # shouldn't matter
      author: scroll_winner
    )

    if open_sentences.any?
      open_sentences.each{|os|
        os.words.each{|w|
          closing_sentence.words << w
        }
      }
      open_sentences.destroy_all
    end

    final_chapter.scroll_words.delete_all
    final_chapter.save

    # todo: set story winner
    # stories.last.update(winner: write_a_method_to_get_this_based_on_signed_sentences)

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