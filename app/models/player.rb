class Player < ApplicationRecord
  has_many :player_legends
  has_many :legends, through: :player_legends
  has_many :legend_wins, class_name: :Legend, foreign_key: :winner_id
  has_many :story_wins, class_name: :Story, foreign_key: :winner_id
  has_many :written_sentences, class_name: :Sentence, foreign_key: :author_id
  belongs_to :active_legend, class_name: :Legend, optional: true, foreign_key: :active_legend_id

  after_validation :check_alias, :check_active_legend
  before_create :set_api_key
  after_save :check_ready

  enum :status, [
    :gone,
    :lobby,
    :playing,
  ]

  def current_game_json
    return nil unless active_legend.present?
    active_legend.current.current_state_json(self)
  end

  def submit_turn(word, sentence_id = nil, sentence_words = [], sign = false)

    # player is adding their own word to the scroll
    is_playing_turn = active_legend.current.player_words.where(player: self, word: word).any?
    if sentence_words.any?
      sentence = active_legend.current.sentences.find_by(id: sentence_id)
      if sentence.nil?
        sentence = active_legend.current.sentences.create(
          author: self,
          signature: sign ? word : nil
        )
      end
      # sentence should always exist here
      sentence.sentence_words.destroy_all

      sentence_words.each{|sw|
        sentence.sentence_words.create(word: sw)
      }

      if is_playing_turn
        # remove all sentence sentence_words from player_words
        active_legend.current.player_words.where(
          word_id: [word.id] + sentence_words.pluck(:id).to_a
        ).delete_all
      end

      # remove all sentence sentence_words from scroll_words
      active_legend.current.scroll_words.where(
        word_id: [word.id] + sentence_words.pluck(:id).to_a
      ).delete_all
    end

    if is_playing_turn
      # if add_scroll_word succeeds, update turn player
      active_legend.current.add_scroll_word(self, word)

      # set next player
      # only supports 2 or 3 players
      next_id = active_legend.current.non_dealers.first.id
      if self.id != active_legend.current.dealer_id
        pids = active_legend.current.story.legend.players.pluck(:id).to_a
        next_id = self.id + 1
        if !pids.include?(next_id)
          next_id = pids.min + (pids.min == self.id ? 1 : 0)
        end
      end
      active_legend.current.update(turn_player_id: next_id)
      active_legend.reload
      # poke the bot player
      BotPlayer.find_by(id: next_id)&.poke
    end
  end

  private

  def spawn_bot(active_legend)
    bot = Player.create(type: BotPlayer, active_legend: active_legend)
    bot.update(alias: "bot#{bot.id}", status: :playing)
    bot
  end

  def set_api_key
    self.api_key = Random.uuid
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

  def check_ready
    if active_legend.present?
      player_legends.create(legend: active_legend) unless player_legends.where(player: self, legend: self.active_legend).any?

      if active_legend.player_count == 1 &&
        active_legend.player_legends.count == 1
        spawn_bot(active_legend)
      end

      if active_legend.created? &&
        active_legend.active_players.count >= 2
        active_legend.started!
      end
    end
  end
end
