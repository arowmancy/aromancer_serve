class Player < ApplicationRecord
  has_many :player_legends
  has_many :legends, through: :player_legends
  has_many :legend_wins, class_name: :Legend, foreign_key: :winner_id
  has_many :story_wins, class_name: :Story, foreign_key: :winner_id
  has_many :written_sentences, class_name: :Sentence, foreign_key: :author_id
  has_many :entries
  belongs_to :active_legend, class_name: :Legend, optional: true, foreign_key: :active_legend_id
  belongs_to :user, optional: true

  after_validation :check_alias, :check_active_legend
  before_create :set_api_key

  class ActiveLegendValidator < ActiveModel::Validator
    def validate(record)
      if record.active_legend.present?
        plids = record.active_legend.player_legends.pluck(:player_id)
        if plids.count == 2 && plids.exclude?(record.id)
          record.errors.add :active_legend, "#{record.alias} is not permitted access to legend #{record.active_legend.id}"
        end
      end
    end
  end
  validates_with ActiveLegendValidator

  enum :status, [
    :gone,
    :lobby,
    :playing,
  ]

  def set_api_key
    self.api_key = SecureRandom.uuid
  end

  def current_language
    player_legends.where(legend: active_legend).first&.mathematica
  end

  def self.score(legend, player)
    Chapter.where(story_id: legend.stories.pluck(:id)).map{|c|
      c.sentences.where.not(signature_id: nil).where(author: player).map{|s| s.weight}.sum
    }.sum.round(1)
  end

  def current_score
    return -1 unless active_legend.present?
    Player.score(active_legend, self)
  end

  def authored_unsigned_sentences
    return [] unless active_legend&.current.present?

    active_legend.current.unsigned_sentences.where(author: self)
  end

  def current_game_json
    return nil unless active_legend.present?

    if active_legend.current.present?
      case active_legend.status.to_sym
      when :started
        return active_legend.current.current_state_json(self)
      when :complete
        return active_legend.final_state_json
      end
    else
      return active_legend.waiting_room
    end
  end

  # expects word to be the "signature word" if sign = true
  def submit_turn(word,
    sentence_id = nil,
    words = [],
    sign = false,
    is_stack = false,
    entry: nil
  )
    entry = active_legend.current.entries.find_by(id: entry&.id) || active_legend.current.entries.create(
      player: self,
      word: word,
      description: "#{self.alias}_submit_turn_#{word.value_display}."
    )
    # player is adding their own word to the scroll
    is_playing_turn = active_legend.current.player_words.where(player: self, word_id: [word.id] + words).any?
    sentence = nil

    if words.any?
      entry_desc = ""
      sentence = active_legend.current.sentences.find_by(id: sentence_id)
      if sentence.nil?
        sentence = active_legend.current.sentences.create(
          author: self,
          signature: sign ? word : nil,
          is_stack: is_stack,
          value: word.value,
          mathematica: current_language
        )
        entry_desc = "#{self.alias}_created_sentence_==>>_"
      else
        entry_desc = "#{self.alias}_modified_sentence:#{sentence.value_display}_==>>_"
        if sign
          sentence.signature = word
          entry_desc = "#{self.alias}_signed_sentence_==>>_"
        end
        sentence.author = self
        sentence.is_stack = is_stack
        sentence.mathematica = current_language unless current_language.nil?
        sentence.save
      end

      # sentence should always exist here
      sentence.sentence_words.destroy_all

      words.each{|wid|
        # destroy all other-sentence associations for each word
        active_legend.current.unsigned_sentences.where.not(
          id: sentence.id
        ).joins(:sentence_words).where(
          sentence_words: {word_id: wid}
        ).destroy_all
        sentence.sentence_words.create(word: wid)
      }

      wids_to_remove = words.pluck(:id).to_a
      wids_to_remove << word.id if word.present?
      wids_to_remove << current_language.id if current_language.present?

      if is_playing_turn
        # remove all words from player_words
        active_legend.current.player_words.where(
          word_id: wids_to_remove
        ).delete_all
      end

      # remove all words from scroll_words
      active_legend.current.scroll_words.where(
        word_id: wids_to_remove
      ).delete_all

      if sentence.sentence_words.any?
        sentence.save
        entry.update(description: entry_desc + sentence.reload.value_display)
      end
    end

    if is_playing_turn
      if word.mathematica?
        # remove from player words
        active_legend.current.player_words.where(word: word).delete_all
        # set language override for one turn
        player_legends.where(legend: active_legend).update_all(mathematica_id: word.id)
      elsif sentence.present?
        # unset language override if sentence is present
        player_legends.where(legend: active_legend).update_all(mathematica_id: nil) if current_language.present?
      else
        # if no sentence, add word to scroll
        active_legend.current.add_scroll_word(self, word)
      end

      # expire writables after player submits turn
      player_legends.find_by(legend: active_legend).writables.destroy_all

      next_id = active_legend.players.where.not(id: self.id).order(id: :asc).first.id
      next_id = self.id unless active_legend.current.player_words.where(player_id: next_id).any?
      active_legend.current.update(turn_player_id: next_id) if active_legend.current.unspoken_words.any?
      active_legend.reload.current # trigger finalization now if no unspoken words

      # generate all possibilities for next player
      # todo: this is currently not running
      Word.generate_possibilities_for_player(active_legend.current.turn_player)

      if active_legend.current.turn_player.kind_of?(BotPlayer)
        # poke the bot player
        active_legend.current.turn_player.poke
      else
        PlayerChannel.broadcast_to(active_legend.current.turn_player, {type: :arena, id: active_legend.id})
      end
    end
  end

  private

  def self.spawn_bot(legend)
    bot = Player.create(type: BotPlayer, active_legend: legend)
    bot.update(alias: "bot#{bot.id}", status: :playing)
    bot
  end

  def check_alias
    if self.alias == :guest.to_s
      self.alias = "guest#{id}"
    end
  end

  def check_active_legend
    self.active_legend_id = nil if active_legend_id == 0 ||
      active_legend_id == :null.to_s

    self.active_legend_id = self.active_legend_id.to_i if self.active_legend_id.kind_of?(String)
  end
end
