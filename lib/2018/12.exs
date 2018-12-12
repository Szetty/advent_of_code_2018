use DataStructures

data =
  "inputs/12"
  |> In.f()

[initial | t] = data
"initial state: " <> state = initial
state = state
alive = t |> reduce(%{}, fn x, acc ->
  [key, value] = x |> String.split("=>") |> map(&String.trim/1)
  Map.put(acc, key, value)
end)
G.set(:alive, alive)

defmodule Simulator do

  @prefix ".."

  def next_gen(state), do: do_next_gen(".." <> state <> "....", "..")

  defp do_next_gen(state, _l) when is_binary(state) and byte_size(state) <= 2, do: state
  defp do_next_gen(<<c::bytes-size(1)>> <> <<r::bytes-size(2)>> <> rest, l) do
    pattern = l <> c <> r
    new = Map.get(G.get(:alive), pattern)
    new = if new !== nil do
      new
    else
      "."
    end
    l = l |> String.slice(1..-1) |> Kernel.<>(c)
    new <> do_next_gen(r <> rest, l)
  end

  def plants(state, i) do
    state
    |> Str.codepoints
    |> with_index
    |> filter(fn {v, _} -> v === "#" end)
    |> map(fn {_v, idx} -> idx + i * -String.length(@prefix) end)
  end

  def sum(plants), do: plants |> Enum.sum
  def shift(plants), do: plants |> map(&Kernel.-(&1, hd(plants)))

end

# first

1..20
|> reduce(state, fn _, state -> Simulator.next_gen(state) end)
|> Simulator.plants(20)
|> Simulator.sum()
|> p

# second

initial_plants = Simulator.plants(state, 0)
states = %{} |> Map.put(Simulator.shift(initial_plants), {0, Simulator.sum(initial_plants)})

{prev_i, prev_sum, i, sum} = loop({1, state, states}, fn {i, state, states} ->
  state = Simulator.next_gen(state)
  plants = state |> Simulator.plants(i)
  shifted = plants |> Simulator.shift()
  old = Map.get(states, shifted)
  sum = Simulator.sum(plants)
  states =
    case old do
      nil -> Map.put(states, shifted, {i, sum})
      {old_i, old_sum} -> throw({old_i, old_sum, i, sum})
    end
  {i + 1, state, states}
end)

((50_000_000_000 - i) / (i - prev_i) * (sum - prev_sum) + sum)
|> to_i
|> p
