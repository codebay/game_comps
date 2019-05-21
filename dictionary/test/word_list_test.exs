defmodule WordListTest do
  use ExUnit.Case

  alias Dictionary.WordList

  test "random_word returns a word" do
    words = ["hello", "test", "today"]
    assert WordList.random_word(words) in words
  end
end
