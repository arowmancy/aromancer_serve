class BotPlayer < Player
  def poke

    return unless active_legend.present?
    return unless active_legend.current.turn_player.id == self.id
    return unless active_legend.started?

    # i look at my cards
    words = Word.where(
      id: active_legend.current.player_words.where(player: self).pluck(:word_id).to_a
    )

    return unless words.any?

    # grab the face cards
    face_cards = words.reject{|word| word.number?}

    if face_cards.any?
      # if i have a face card, i will play it for now
      # todo: more bot logic
      submit_turn(Word.find(face_cards.first.id))
    else
      # todo: more bot logic
      submit_turn(words.first)
    end
  end
end