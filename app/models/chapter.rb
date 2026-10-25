class Chapter < ApplicationRecord
  # *scroll (used words)
  #
  # a stack of 2 or more words, one of which "writes" the sentence.
  # whichever player produces the signature word from their unspoken words
  # automatically becomes the author. all words exit the scroll via
  # sentences. at the end of each story, player stats are updated
  # using the sum of all word-points values that are included
  # in the player's authored sentences. this value is then added to the
  # global stats for each player.
  has_many :sentences
  has_many :unsigned_sentences, -> { where(signature: nil) }, class_name: Sentence.to_s
  # class Sentence < ApplicationRecord
  #   belongs_to :author
  #   belongs_to :chapter
  #   belongs_to :signature
  # end

  # *scroll (unused words)
  #
  # join table: chapter_id_word_id
  # plain english: "word ids visible and combine-able to all players"
  has_many :scroll_words
  # all words shown on the scroll (not used in sentence)
  has_many :unwritten_words, through: :scroll_words, source: :word

  # *player "hand"
  #
  # join table: chapter_id_player_id_word_id
  # plain english: "unplayed word ids grouped by player"
  has_many :player_words
  # all words dealt to players currently in-play.
  has_many :unspoken_words, through: :player_words, source: :word

  has_many :entries

  # the story that this chapter belongs to
  belongs_to :story

  belongs_to :turn_player, class_name: :Player, foreign_key: :turn_player_id

  def start
    nds = non_dealers
    11.times do
      # deal to non-dealer players
      nds.each{|nd| deal_one_word(nd)}

      # deal to dealer
      deal_one_word(story.dealer)
    end

    # poke the bots
    story.legend.players.where(type: BotPlayer.to_s).each{|bp|
      bp.poke
    }
  end

  def add_scroll_word(player, word)
    unless player.id == turn_player.id
      entries.last.update(
        description: (entries.last.description || "") +
        " rollback transaction because (player.id = turn_player.id) check failed."
      )
      return
    end
    # do nothing unless the word is playable by the player
    playable_words = player_words.where(player_id: player.id, word_id: word.id)
    unless playable_words.any?
      entries.last.update(
        description: (entries.last.description || "") +
        " rollback transaction because (playable_words.any?) check failed."
      )
      return
    end

    begin
      # word valid for play...
      # move word from player_words to scroll_words
      pw = playable_words.find_by(player_id: player.id, word_id: word.id)
      # delete the player_word record and add the scroll_word record
      pw.destroy && scroll_words.create(word_id: word.id)
    rescue StandardError => e
      entries.last.update(
        description: (entries.last.description || "") +
        " rollback transaction because #{e.message}"
      )
    end
  end

  def current_state_json(for_player)
    bot_player = BotPlayer.where(id: story.legend.players.pluck(:id)).first
    {
      title: "#{self.class.name.downcase} #{nzindex_number}",
      dealer: player_json(story.dealer).except(:words),
      turn_player: player_json(turn_player).except(:words),
      scroll_words: unwritten_words.sort_by{|w| [w.value, w.suit]}.map{|w| w.json_card},
      sentences: unsigned_sentences.map{|s| s.json_sentence},
      player: player_json(for_player, for_player),
      players: story.legend.players.map{|p| player_json(p).except(:words)},
      bot_player: bot_player.present? ? player_json(bot_player, bot_player) : nil
    }
  end

  def player_json(player, for_player = nil)
    json_result = {
      id: player.id,
      status: player.status,
      alias: "#{player.alias}#{player.current_language.present? ? "(#{player.current_language.value_display})" : ""}",
      score: player.current_score,
      words: unspoken_words.where(
        id: player_words.where(player: player).pluck(:word_id)
      ).sort_by{|w|
        [w.value, w.style, w.suit]
      }.map{|w|
        player == for_player ? w.json_card : {}
      }
    }

    if for_player.present? && player == for_player
      json_result[:sentences] =
        sentences.where.not(signature_id: nil).where(author: player).map{|s| s.json_sentence}
    end

    json_result
  end

  def deal_one_word(player)
    return if self.is_final
    # get the top word
    word = story.dictionary.get_top_word

    # last chapter in the story,
    # dictionary is empty.
    if word.nil?
      update(is_final: true)
      return
    end

    player_words.create(player: player, word: word)
  end

  def non_dealers
    @non_dealers ||= story.legend.players.where.not(id: story.dealer.id)
  end

  # non-zero-based indexing (eg 1,2,3...)
  def nzindex_number
    story.chapters.pluck(:id).index(self.id) + 1
    # (self.id - story.chapters.first.id) + 1
  end
end

