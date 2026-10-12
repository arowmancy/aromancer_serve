require_relative "../controllers/concerns/arena"

class BotPlayer < Player
  include Arena

  def poke

    return unless active_legend.present?
    return unless active_legend.started?
    return unless active_legend.current.turn_player.id == self.id

    words = Word.where(
      id: active_legend.current.player_words.where(player: self).pluck(:word_id)
    )

    return unless words.any?

    option = nil
    max_retries = rand(11..22)
    retries = 0
    while option.nil? && retries <= max_retries
      possibilities = words.sample.possibilities(self)
      # Rails.logger.info possibilities.inspect
      option = possibilities[:options].select{|o| !o[:payload].blank?}.sample
      # Rails.logger.info option.inspect
      retries += 1 if option.nil?
    end

    if option.present?
      # valid word option
      arena = JSON.parse(option[:payload]).symbolize_keys
      # Rails.logger.info arena.inspect

      if option[:http_verb] == :post
        process_arena_create(arena, active_legend.current, self)
      else
        process_arena_update(arena, active_legend.current, self)
      end
    else
      submit_turn(words.sample)
    end
  end

  def respond_with_error(head_response, message, object = nil, param_structure = nil)
    Rails.logger.info "bot error: #{head_response}: #{message}"
  end
end