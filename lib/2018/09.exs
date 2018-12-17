use DataStructures

number_regex = ~r/\d+/

data =
  "inputs/09"
  |> In.f()

[players_nr, marbles_nr] = Regex.scan(number_regex, hd(data)) |> map(&Kernel.hd/1) |> map(&to_i/1)

defmodule ETS.Map do

  def new(name, options \\ [:named_table, :public]) do
    :ets.new(name, options)
  end

  def get(name, key) do
    :ets.lookup_element(name, key, 2)
  end

  def put(name, key, value) do
    :ets.insert(name, {key, value})
  end

  def delete(name) do
    :ets.delete(name)
  end

end

simulate = fn marbles_nr ->
  ETS.Map.new(:forward)
  ETS.Map.put(:forward, 0, 0)
  ETS.Map.new(:backward)
  ETS.Map.put(:backward, 0, 0)

  {scores, _} = 1..marbles_nr
  |> reduce({%{}, 0}, fn marble, {scores, current_marble} ->
    if rem(marble, 23) === 0 do
      to_remove = reduce(1..7, current_marble, fn _, cur -> ETS.Map.get(:backward, cur) end)
      player = rem(marble, players_nr)
      scores = Map.put(scores, player, Map.get(scores, player, 0) + marble + to_remove)
      b = ETS.Map.get(:backward, to_remove)
      f = ETS.Map.get(:forward, to_remove)
      ETS.Map.put(:forward, b, f)
      ETS.Map.put(:backward, f, b)
      {scores, f}
    else
      b = ETS.Map.get(:forward, current_marble)
      f = ETS.Map.get(:forward, b)
      ETS.Map.put(:forward, marble, f)
      ETS.Map.put(:forward, b, marble)
      ETS.Map.put(:backward, marble, b)
      ETS.Map.put(:backward, f, marble)
      {scores, marble}
    end
  end)
  ETS.Map.delete(:forward)
  ETS.Map.delete(:backward)
  scores
  |> Map.values
  |> max
  |> p
end

#first

simulate.(marbles_nr)

#second

simulate.(marbles_nr * 100)
