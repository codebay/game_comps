defmodule TextClient.Mover do
  alias TextClient.State

  def make_move(game) do
    Hangman.make_move(game.game_service, game.guess)
    %State{ game | tally: Hangman.tally(game.game_service) }
  end
end