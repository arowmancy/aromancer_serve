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

  enum :status, [
    :gone,
    :lobby,
    :playing,
  ]

  def set_api_key
    self.api_key = Random.uuid
  end

  def current_game_json
    unless active_legend.present?
      return {title: "loading..."}
    end

    if active_legend.current.present? && active_legend.started?
      active_legend.current.current_state_json(self)
    else
      active_legend.waiting_room
    end
  end

  # expects word to be the "signature card" if sign = true
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
      description: "#{self.alias} submitting turn..."
    )
    # player is adding their own word to the scroll
    is_playing_turn = active_legend.current.player_words.where(player: self, word: word).any?
    sentence = nil

    if words.any?
      sentence = active_legend.current.sentences.find_by(id: sentence_id)
      if sentence.nil?
        sentence = active_legend.current.sentences.create(
          author: self,
          signature: sign ? word : nil,
          is_stack: is_stack,
          value: word.value
        )
        entry.update(description: (entry.description || "") + " created sentence: #{sentence.to_json}")
      else
        if sign
          sentence.signature = word
          sentence.author = self
          entry.update(description: (entry.description || "") + " signed sentence: #{sentence.to_json}")
        end
        sentence.is_stack = is_stack
        sentence.save
      end

      # sentence should always exist here
      sentence.sentence_words.destroy_all

      words.each{|wid|
        sentence.sentence_words.create(word: wid)
      }

      wids_to_remove = words.pluck(:id).to_a
      if word.present?
        wids_to_remove << word.id
      end

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

      sentence.save if sentence.sentence_words.any?
    end

    if is_playing_turn
      active_legend.current.add_scroll_word(self, word) unless sentence.present? # already took care of it

      return unless active_legend.current.unspoken_words.any?

      next_id = active_legend.players.where.not(id: self.id).order(id: :asc).first.id
      active_legend.current.update(turn_player_id: next_id)
      active_legend.reload
      PlayerChannel.broadcast_to(active_legend.current.turn_player, {type: :arena, id: active_legend.id})

      # poke the bot player
      BotPlayer.find_by(id: next_id)&.poke
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
