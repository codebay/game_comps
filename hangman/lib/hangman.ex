defmodule Hangman do
  alias Hangman.GameComp

  defdelegate new_game(), to: GameComp, as: :create
  defdelegate end_game(pid), to: GameComp, as: :destroy

  defdelegate tally(pid), to: GameComp
  defdelegate make_move(pid, guess), to: GameComp
end
