# Description

This repo contains a modification of the [Hangman game](https://github.com/pragdave/e4p-code) from Dave Thomas's course [Elixir for Programmers](https://codestool.coding-gnome.com) to utilise Dave's recent [Component Library](https://github.com/pragdave/component).

## Why

I've been experimenting with Dave's Component Library on a few projects which follow Dave's design approach [Splitting APIs, Servers, and Implementations in Elixir](https://pragdave.me/blog/2017/07/13/decoupling-interface-and-implementation-in-elixir.html).

In this repo I want to show how I've have used the component library on a simple example that illustrates some of the practises that I've have found useful. To this end I've have taken some of the code from Dave's `Elixir for Programmers' course and used the component library.

I recommend that unless you are familiar with Dave's course or the Component library you follow the links above before before continuing, or it might not make a lot of sense.

The Hangman game is made up of two servers: `Dictionary` which provides a random word from a word list and `Hangman` which provides the business logic of the game, and text based client `TextClient`.

## Making the Dictionary into a Global Component

Below shows the initial directory tree and code after developing the implementation logic and before making any modifications. The `lib` directory contains the Dictionary API `dictionary.ex` and in the sub-directory called `dictionary` has the implementation code `word_list.ex`. 

```
lib
   dictionary
      word_list.ex
   dictionary.ex
test
   word_list_test.ex         
```

The file `word_list.ex` contains two simple functions word_list to provide a list of words, and random_word which extracts a single random word:

```
defmodule Dictionary.WordList do
  def word_list() do
    "../../assets/words.txt"
    |> Path.expand(__DIR__)
    |> File.read!()
    |> String.split("\n", trim: true)
  end

  def random_word(word_list) do
    word_List
    |> Enum.random()
  end
end
```

and `dictionary.ex` which defines the API by two delegates to provide a word list, and a random word from a word list.

```
defmodule Dictionary do
  alias Dictionary.WordList

  defdelegate word_list(), to: WordList
  defdelegate random_word(word_list), to: WordList
end
```

There is also a simple unit test, that I included for illustration

```
defmodule WordListTest do
  use ExUnit.Case

  alias Dictionary.WordList

  test "random_word returns a word" do
    words = ["hello", "test", "today"]
    assert WordList.random_word(words) in words
  end
end
```

To change this to a Global component that runs as a singleton process, the simple way would be to change the word_list.ex file as shown below:

```
defmodule Dictionary do

  use Component.Strategy.Global,
      state_name:    :word_list,
      initial_state: word_list()

  two_way random_word() do
    word_list
    |> Enum.random()
  end

  defp word_list() do
    "../assets/words.txt"
    |> Path.expand(__DIR__)
    |> File.read!
    |> String.split("\n", trim: true)
  end
end
```

However I've have found the better strategy is keep to Dave's design strategy with a separation of concerns, by creating a new file `word_list_comp.ex` for the component definition, and leaving the implementation in `word_list.ex` alone.

#### word_list_comp.ex

```
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
```

This way the `word_list.ex` remains untouched and the unit tests continue to function without any modifications.

The dictionary API will need a little modification to account for the word list now being kept in the global components state.

```
defmodule Dictionary do
  alias Dictionary.WordList

  defdelegate random_word(), to: WordList
end
```

## Making the Hangman into a Dynamic Component

The `Hangman` directory structure is similar to the `Dictionary` with an API, implementation code and tests.

The game logic is in the file `game.ex` in a `game` directory under `lib`

```
defmodule Hangman.Game do
  defstruct(
    turns_left: 7,
    game_state: :initializing,
    letters: [],
    used: MapSet.new()
  )

  def new_game(word) do
    %Hangman.Game{
      letters: word |> String.codepoints()
    }
  end

  def new_game() do
    Dictionary.random_word()
    |> new_game()
  end

  def make_move(game = %{game_state: state}, _guess) when state in [:won, :lost] do
    game
    |> return_with_tally()
  end

  def make_move(game, guess) do
    accept_move(game, guess, MapSet.member?(game.used, guess))
    |> return_with_tally()
  end

  def tally(game) do
    %{
      game_state: game.game_state,
      turns_left: game.turns_left,
      letters: game.letters |> reveal_guessed(game.used)
    }
  end

  ##################################################

  defp return_with_tally(game) do
    {game, tally(game)}
  end

  defp accept_move(game, _guess, _already_guessed = true) do
    Map.put(game, :game_state, :already_used)
  end

  defp accept_move(game, guess, _already_guessed) do
    Map.put(game, :used, MapSet.put(game.used, guess))
    |> score_guess(Enum.member?(game.letters, guess))
  end

  defp score_guess(game, _good_guess = true) do
    new_state =
      MapSet.new(game.letters)
      |> MapSet.subset?(game.used)
      |> maybe_won()

    Map.put(game, :game_state, new_state)
  end

  defp score_guess(game = %{turns_left: 1}, _not_good_guess) do
    %{game | game_state: :lost, turns_left: 0}
  end

  defp score_guess(game = %{turns_left: turns_left}, _not_good_guess) do
    %{game | game_state: :bad_guess, turns_left: turns_left - 1}
  end

  defp reveal_guessed(letters, used) do
    letters
    |> Enum.map(fn letter -> reveal_letter(letter, MapSet.member?(used, letter)) end)
  end

  defp reveal_letter(letter, _in_word = true), do: letter
  defp reveal_letter(_letter, _not_in_word), do: "_"

  defp maybe_won(true), do: :won
  defp maybe_won(_), do: :good_guess
end
```

The public API comprises of the functions `new_game`, `make_move` and `tally`.

This time the simple approach of applying the component library to `game.ex` above would not be so simple and require quite a few changes. The main problems would be:

- the `make_move` function would use the `one_way` declarations because the state is changed, however currently the function returns the new state and a tally.

- the `make_move` has a second problem, as one function uses pattern matching to extract the game state and the component library cannot handle this situation.

- the code in the `one_way` and `two_way` functions will execute inside there own module so direct calls to the supporting private functions will not work. Dave's offers in his [Component guide](https://github.com/pragdave/component) a solution by moving these supporting functions to one or more separate modules.

However all these changes will break the unit tests, which also will need changing.

As before a better strategy is to create a new file for the component implementation, and leave the `game.ex` file alone.

#### game_comp.ex

```
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

```

In this component implementation I've corrected for the `make_move` function returning the state and the tally.

The original hangman API

```
defmodule Hangman do
  alias Hangman.Game
  
  defdelegate new_game(),             to: Game
  defdelegate tally(game),            to: Game
  defdelegate make_move(game, guess), to: Game
end
```

Will need modification because again the state is being retained within the component, and also to provide more appropriate alternative names for the `create` and `distory` functions created in the component library.

```
defmodule Hangman do
  alias Hangman.GameComp

  defdelegate new_game(), to: GameComp, as: :create
  defdelegate end_game(pid), to: GameComp, as: :destroy

  defdelegate tally(pid), to: GameComp
  defdelegate make_move(pid, guess), to: GameComp
end
```

### If you want to playing the Hangman game

```
$ cd text_client
$ mix run -e TextClient.start

Word so far: _ _ _ _ _ _ _ _
Guesses left 7

Your guess: a
Good Guess

Word so far: a _ _ _ _ _ _ _
Guesses left 7

Your guess: o
Good Guess

Word so far: a _ _ _ _ o _ _
Guesses left 7

Your guess: b
Sorry, that isn't in the word!

Word so far: a _ _ _ _ o _ _
Guesses left 6

Your guess:

.....
```

### Use the Dictionary Component separately

```
$ cd dictionary
$ iex -S mix

iex(1)> Dictionary.random_word
"fear"

iex(2)> Dictionary.random_word
"variations"

iex(3)> Dictionary.random_word
"laboratory"

iex(4)> Dictionary.random_word
"anything"

.....
```

### Use the Hangman Component separately

```
$ cd hangman
$ iex -S mix

iex(1)> pid = Hangman.new_game()

iex(2)> Hangman.make_move(pid, "a")
:ok

iex(3)> Hangman.tally(pid)
%{
  game_state: :good_guess,
  letters: ["_", "a", "_", "_", "_", "_", "_"],
  turns_left: 7
}

iex(4)> Hangman.make_move(pid, "e")
:ok

iex(5)> Hangman.tally(pid)         
%{
  game_state: :bad_guess,
  letters: ["_", "a", "_", "_", "_", "_", "_"],
  turns_left: 6
}

iex(6)> Hangman.make_move(pid, "u")
:ok

iex(7)> Hangman.tally(pid)         
%{
  game_state: :good_guess,
  letters: ["_", "a", "_", "_", "u", "_", "_"],
  turns_left: 5
}

.....
```