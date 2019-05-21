defmodule Dictionary.WordListComp do
  alias Dictionary.WordList

  use Component.Strategy.Global,
    state_name: :words,
    initial_state: WordList.word_list(),
    top_level: true

  two_way random_word() do
    WordList.random_word(words)
  end
end
