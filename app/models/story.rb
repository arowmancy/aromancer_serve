class Story < ApplicationRecord
  belongs_to :legend
  belongs_to :winner, class_name: :Player, optional: true, foreign_key: :winner_id
  has_many :chapters
  has_one :dictionary

  # dealer alternates across each story in a legend
  belongs_to :dealer, class_name: :Player, foreign_key: :dealer_id

  TOTAL_POINTS = 11.to_f

  def start
    return if legend.active_players.count != 2
    return if chapters.where(is_final: true).present?

    Dictionary.create(story: self) if dictionary.nil?
    last_scroll_words = chapters.last&.scroll_words || []
    last_unsigned_sentences = chapters.last&.unsigned_sentences || []
    @current_chapter = chapters.create(
      turn_player: legend.players.where.not(id: dealer.id).first
    )
    last_scroll_words&.update_all(chapter_id: @current_chapter.id) if last_scroll_words.any?
    last_unsigned_sentences&.update_all(chapter_id: @current_chapter.id) if last_unsigned_sentences.any?
    @current_chapter.start
    @current_chapter.reload
    PlayerChannel.broadcast_to(@current_chapter.turn_player, {type: :arena, id: legend.id})
    @current_chapter
  end

  def current_chapter
    @current_chapter ||= chapters.to_a.filter{|c| c.unspoken_words.any?}.first || start
  end

  def finalize!
    return unless winner.nil?
    # end of story
    final_chapter = chapters.last
    return unless final_chapter.present? && final_chapter.is_final

    return unless final_chapter.unspoken_words.any? ||
      final_chapter.unsigned_sentences.any?

    scroll_winner = final_chapter.sentences.where.not(signature: nil).order(updated_at: :asc).last&.author
    if scroll_winner.nil?
      Rails.logger.debug("expected scroll_winner to be author of last signed sentence but found nothing")
      scroll_winner = legend.players.first
    end

    # create final sentence to hold everything left on the scroll
    closing_sentence = final_chapter.sentences.create(
      value: 0,
      words: dictionary.words.where(id: final_chapter.scroll_words.pluck(:word_id)),
      signature: final_chapter.scroll_words.first.word, # shouldn't matter
      author: scroll_winner
    )

    # remove all words from the scroll
    final_chapter.scroll_words.destroy_all

    if final_chapter.unsigned_sentences.any?
      # move all words from unsigned sentences to final sentence
      final_chapter.unsigned_sentences.each{|us|
        us.words.each{|w|
          w.sentence_words.destroy_all
          closing_sentence.words << w
        }
      }
      final_chapter.unsigned_sentences.destroy_all
    end

    final_chapter.save

    update(winner: legend.players.max{|p| Player.score(legend, p)})
  end
end
