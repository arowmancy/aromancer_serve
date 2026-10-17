# [aromancer_serve](https://github.com/arowmancy/aromancer_serve)
## legend
### story
#### dictionary
#### chapter
##### scroll
###### sentence
###### word
###### [aromancer](https://rubygems.org/gems/aromancer)

`app/models/dictionary.rb` "the deck."
```ruby
# standard 78-card tarot deck with 6 mathematica operator words:
#
# 2-each of ["-", "×", "÷"]
#
# note: there are no "+" mathematica words because this
# is the default "language" of each sentence.
#
# total count in a dictionary is 84 words.
# one "story" is one full pass through the full tarot
# deck broken down by chapters.
#
# players are dealt the same number of words in each chapter.
#
# a standard 2-player story has 4 chapters
#
#   2 players x 11 words/each x 3 chapters = 66 words
#   2x11x3=(66) words each (3 chapters)
#
#   2 players x 18 words/each x 1 chapter = 18 words
#   2x9x1 =(18) words each (last chapter)
#
# total: 84 = 66+18
#
```

`app/models/word.rb` "the card."
```ruby
def weight
  # aromancer rules:

  # => each story has a total possible of 11 points.
  # => addition is the default language.
  # => mathematica words change the player's language for their next sentence.

  # scoring:

  # 1 => most words
  # 1 => most trumps
  # 1 => most face words
  # 1 => most swords (masculine)
  # 1 => most wands (masculine)
  # 1 => ten of cups (feminine)
  # 1 => ten of pentacles (feminine)
  # 4 => aces (1 each)

  # the following code is where the score is calculated:

  # mathematica words get zero weight
  return 0 if mathematica?
  # self is a non-mathematica word
  wt = (1.0 / 78.0) if true == true
  # self is a trumps word
  wt += (1.0 / 22.0) if self.trumps?
  # self is a face word
  wt += (1.0 / 16.0) unless self.number? || self.trumps?
  # self is a 10 of cups or pentacles
  wt +=  1.0 if (self.cups? || self.pentacles?) && self.value == 10
  # self is a swords or wands
  wt += (1.0 / 14.0) if (self.swords? || self.wands?)
  # self is an ace
  wt +=  1.0 if self.value == 1 && self.number? && !self.trumps?

  # return total weight
  wt
end
```

### run a `127.0.0.1` aromancer game server:


```bash
gem install aromancer && aromancer serve
```
> then, from different terminal run
```bash
aromancer
```
#### `in-game`
> go to `configure` and verify settings

[rubygems](https://rubygems.org/gems/aromancer)
[license](http://opensource.org/licenses/MIT)
[issues](https://github.com/arowmancy/aromancer_serve/issues)

#### aromancer_serve by arowmancy is copyright (2026)
