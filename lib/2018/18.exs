use DataStructures

grid =
  "inputs/18"
  |> In.f(column: "")
  |> A.new

open = "."
tree = "|"
lumber = "#"

is = &Kernel.===/2

map_idx = fn grid, idx -> grid[idx] end

change_acre = fn grid, i, j, el ->
  neighbours = [
    {i, j - 1},        # west
    {i, j + 1},        # east
    {i + 1, j},     # south
    {i - 1, j},     # north
    {i + 1, j - 1}, # south-west
    {i + 1, j + 1}, # south-east
    {i - 1, j - 1}, # north-west
    {i - 1, j + 1}, # north-east
  ]
  |> map(&map_idx.(grid, &1))
  case el do
    ^open ->
      if count(neighbours, &is.(&1, tree)) >= 3 do
        tree
      else
        open
      end
    ^tree ->
      if count(neighbours, &is.(&1, lumber)) >= 3 do
        lumber
      else
        tree
      end
    ^lumber ->
      if count(neighbours, &is.(&1, lumber)) >= 1 && count(neighbours, &is.(&1, tree)) >= 1 do
        lumber
      else
        open
      end
  end
end

change = fn grid ->
  grid
  |> A.map_rec(fn [j, i], acre ->
    change_acre.(grid, i, j, acre)
  end)
end

to_string = fn grid ->
  grid |> map(&join/1) |> join("\n")
end

display = fn grid ->
  to_string.(grid) |> IO.puts
  IO.puts("\n")
end

total_resource_value = fn grid ->
  trees = grid |> map(fn row -> row |> count(&is.(&1, tree)) end) |> sum
  lumbers = grid |> map(fn row -> row |> count(&is.(&1, lumber)) end) |> sum
  trees * lumbers
end

simulate = fn grid, times ->
  try do
    {_grids, grid} = 1..times
    |> reduce({%{}, grid}, fn i, {grids, grid} ->
      new_grid = change.(grid)
      str = to_string.(new_grid)
      if Map.has_key?(grids, str) do
        old_idx = grids[str]
        cycle_nr = i - old_idx
        r = rem(times - i, cycle_nr)
        throw(grids[i - cycle_nr + r])
      end
      grids = Map.put(grids, str, i) |> Map.put(i, new_grid)
      {grids, new_grid}
    end)
    grid
  catch
    x -> x
  end
end

# first

grid |> simulate.(10) |> total_resource_value.() |> p

# second

grid |> simulate.(1_000_000_000) |> total_resource_value.() |> p
