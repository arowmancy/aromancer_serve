require_relative "../controllers/concerns/arena"

class BotPlayer < Player

  def poke

    return unless active_legend.present?
    return unless active_legend.started?
    return unless active_legend.current.turn_player.id == self.id

    words = Word.where(
      id: active_legend.current.player_words.where(player: self).pluck(:word_id)
    )

    return unless words.any?

    # todo:
    # check if any sentences can be combined
    # check for highest value builder sentence

    option = nil
    max_retries = rand(11..22)
    retries = 0
    while option.nil? && retries <= max_retries
      possibilities = words.sample.possibilities(self)
      # Rails.logger.info possibilities.inspect

      option = possibilities[:options].max{|o| o[:total_weight]}
      # Rails.logger.info option.inspect
      retries += 1 if option.nil?
    end

    handled = false
    if option.present?
      writable_option = WritableOption.find_by(uuid: option[:uuid])

      if writable_option.present?
        writable_option.write!
        handled = true
      end
    end

    submit_turn(active_legend.current.player_words.where(player: self).sample.word) unless handled

  end
end