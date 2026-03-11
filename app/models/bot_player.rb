class BotPlayer < Player
  def poke

    return unless active_legend.present?
    chapter = Chapter.find_by(id: active_legend.current.id)
    return unless chapter.present?
    return unless chapter.turn_player.id == self.id

    # i look at my cards
    words = Word.where(id: chapter.player_words.where(player: self).pluck(:word_id).to_a)
    puts words

    # grab the face cards
    face_cards = words.reject{|word| word.number?}

    # if i have a face card, i will play it for now
    if face_cards.any?

      # if add_scroll_word succeeds, update turn player
      if chapter.add_scroll_word(self, Word.find(face_cards.first.id))

        # only supports 2 or 3 players
        if self.id == chapter.dealer_id
          chapter.update(turn_player_id: chapter.non_dealers.first.id)
        else
          pids = chapter.story.legend.players.pluck(:id).to_a
          next_id = self.id + 1
          if !pids.include?(next_id)
            next_id = pids.min + (pids.min == self.id ? 1 : 0)
          end
          chapter.update(turn_player_id: next_id)
        end
      end
    end
  end
end