defmodule Hangman.GameComp do
  alias Hangman.Game

  use Component.Strategy.Dynamic,
    state_name: :game,
    initial_state: Game.new_game(),
    top_level: true

  one_way make_move(guess) do
    {game, _} = Game.make_move(game, guess)
    game
  end

  two_way tally() do
    Game.tally(game)
  end
end
