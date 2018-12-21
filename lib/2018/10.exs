use DataStructures

grid =
  "inputs/10"
  |> In.f()
  |> map(fn x ->
    [[x], [y], [dx], [dy]] = Regex.scan(~r/-?\d+/, x)
    {{to_i(x), to_i(y)}, [{to_i(dx), to_i(dy)}]}
  end)
  |> into(%{})

{minx, maxx} = grid |> map(fn {{x, _}, _} -> x end) |> min_max
{miny, maxy} = grid |> map(fn {{_, y}, _} -> y end) |> min_max

xr = minx..maxx |> p
yr = miny..maxy |> p

display = fn grid, seconds ->
  {minx, maxx} = grid |> map(fn {{x, _}, _} -> x end) |> min_max
  {miny, maxy} = grid |> map(fn {{_, y}, _} -> y end) |> min_max
  size = len(grid)
  if (maxx - minx) * (maxy - miny) < size * 100 do
    for y <- miny..maxy do
      for x <- minx..maxx do
        if grid[{x, y}] !== nil do
          "#"
        else
          "."
        end
      end
      |> join
    end
    |> join("\n")
    |> IO.puts
    IO.puts(seconds)
    IO.puts("\n\n")
    :timer.sleep(2000)
  end
end

move = fn grid ->
  reduce(grid, %{}, fn {{x, y}, velocities}, new_grid ->
    reduce(velocities, new_grid, fn {dx, dy}, new_grid ->
      new_pos = {x + dx, y + dy}
      values = Map.get(new_grid, new_pos, [])
      Map.put(new_grid, new_pos, [{dx, dy} | values])
    end)
  end)
end

loop({grid, 0}, fn {grid, seconds} ->
  grid = move.(grid)
  seconds = seconds + 1
  display.(grid, seconds)
  {grid, seconds}
end)
