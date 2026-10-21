class WritableOption < ApplicationRecord
  include Arena
  include Uuid

  belongs_to :writable

  def write!
    # writable_option payload example:

    # body: json
    # http_verb: http_verb,
    # value: numeric

    parsed = JSON.parse(payload).symbolize_keys
    body = (parsed[:body] || {}).symbolize_keys
    Thread.current[:writable_option_id] = self.id
    Rails.logger.debug "writing writable option:"
    Rails.logger.debug parsed
    if parsed[:http_verb] == :put.to_s
      process_arena_update(
        body,
        writable.player_legend.legend.current,
        writable.player_legend.player,
        entry_text: parsed[:entry_text].strip.gsub(" ", "_")
      )
    else
      process_arena_create(
        body,
        writable.player_legend.legend.current,
        writable.player_legend.player,
        entry_text: parsed[:entry_text].strip.gsub(" ", "_")
      )
    end
    Thread.current[:writable_option_id] = nil
  end

  private

  def respond_with_error(head_response, message, object = nil, param_structure = nil)
    Rails.logger.info "arena error:"
    Rails.logger.info("head_response: #{head_response}")
    Rails.logger.info("message: #{message}")
    Rails.logger.info("object: #{object || message}")
    Rails.logger.info("param_structure: #{param_structure || @param_structure}")
  end
end
