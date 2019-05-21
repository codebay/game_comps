defmodule Dictionary do
  alias Dictionary.WordListComp

  defdelegate random_word(), to: WordListComp
end
