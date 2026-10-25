require_relative "../controllers/concerns/arena"

class BotPlayer < Player

  def get_best_option
    words = Word.where(
      id: active_legend.current.player_words.where(player: self).pluck(:word_id)
    )

    return false unless words.any?

    # snapshot of bot's current language
    original_mathematica_id = active_legend.player_legends.find_by(player: self)&.mathematica_id

    # get best option from bot's player words
    option = max_weight_option(words)

    m_words = words.filter{|w| w.mathematica?}
    math_option = nil
    unless original_mathematica_id.nil? && (option.nil? || m_words.empty?)
      m_words.each{|m|
        active_legend.player_legends.find_by(player: self).update(mathematica_id: m.id)
        math_option = max_weight_option(words)
        if math_option.present?
          if math_option[:total_weight] < option[:total_weight]
            math_option = nil
          else
            math_option = m
          end
        end
      }
      active_legend.player_legends.find_by(player: self).update(mathematica_id: original_mathematica_id)
    end

    if math_option.kind_of?(Word)
      submit_turn(math_option)
      return true
    end

    option
  end

  def max_weight_option(words)
    max = 0
    option = nil
    words.each{|w|
      poss = w.possibilities(self)[:options].max{|o| o[:total_weight]}
      if poss.present? && max < poss[:total_weight]
        max = poss[:total_weight]
        option = poss
      end
    }

    option
  end

  def poke
    return unless active_legend.present?||
      active_legend.started? ||
      active_legend.current&.turn_player.id == self.id


    # todo:
    # check if any sentences can be combined
    option = get_best_option
    handled = false
    if ![true, false].include?(option) && option.present?
      writable_option = WritableOption.find_by(uuid: option[:uuid])

      if writable_option.present?
        writable_option.write!
        handled = true
      end
    end

    submit_turn(active_legend.current.player_words.where(player: self).sample.word) unless handled || option == true
  end
end