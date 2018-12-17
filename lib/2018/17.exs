use DataStructures


spring_coord = {500, 0}
spring = "+"
sand = nil
static_water = "~"
flowing_water = "|"
clay = "#"

mapper = fn line ->
  [first, second] = Str.split(line, ", ")
  [fc, fv] = Str.split(first, "=")
  [_, sv] = Str.split(second, "=")
  [first, last] = Str.split(sv, "..") |> map(&to_i/1)
  first_range = to_i(fv)..to_i(fv)
  second_range = first..last
  if fc === "x" do
    {first_range, second_range}
  else
    {second_range, first_range}
  end
end

spread_horizontal = fn grid, cur, dir ->
  loop({grid, cur}, fn {grid, {curx, cury}} ->
    next = {curx + dir, cury}
    below = {curx, cury + 1}
    if grid[below] === sand || grid[below] === flowing_water do
      throw({grid, [{curx, cury}]})
    else
      if grid[next] !== clay && grid[next] !== static_water do
        grid = Map.put(grid, next, static_water)
        {grid, next}
      else
        throw({grid, []})
      end
    end
  end)
end

make_flow_water = fn grid, cur, dir ->
  loop({grid, cur}, fn {grid, {curx, cury}} ->
    next = {curx + dir, cury}
    below = {curx, cury + 1}
    if grid[next] === static_water && grid[below] !== sand do
      grid = Map.put(grid, next, flowing_water)
      {grid, next}
    else
      throw(grid)
    end
  end)
end

overflow = fn grid, cur ->
  grid
  |> Map.put(cur, flowing_water)
  |> make_flow_water.(cur, 1)
  |> make_flow_water.(cur, -1)
end

spread = fn grid, {curx, cury} = cur ->
  next = {curx, cury + 1}
  case grid[next] do
    ^sand ->
      grid = Map.put(grid, next, flowing_water)
      {grid, [next]}
    n when n in [static_water, clay] ->
      {grid, r} =
        grid
        |> Map.put({curx, cury}, static_water)
        |> spread_horizontal.(cur, 1)
      {grid, l} = grid |> spread_horizontal.(cur, -1)
      case l ++ r do
        [] ->
          {grid, [{curx, cury - 1}]}
        l when is_list(l) ->
          {overflow.(grid, {curx, cury}), l}
      end
    ^flowing_water ->
      {grid, []}
  end
end

simulate = fn grid, max_y ->
  loop({grid, [spring_coord]}, fn {grid, curs} ->
    if all?(curs, fn {_, cury} -> cury > max_y end) do
      throw(grid)
    end
    reduce(curs, {grid, []}, fn cur, {grid, next} ->
      {grid, curs} = spread.(grid, cur)
      {grid, next ++ curs}
    end)
  end)
end

display = fn grid, yr, xr ->
  yr
  |> map(fn y ->
    xr |> map(&Map.get(grid, {&1, y}, ".")) |> join
  end)
  |> join("\n")
  |> IO.puts
end

clay_coords =
  "inputs/17"
  |> In.f()
  |> map(mapper)

min_y = clay_coords |> map(fn {_, first.._last} -> first end) |> min
max_y = clay_coords |> map(fn {_, _first..last} -> last end) |> max

grid =
  reduce(clay_coords, %{}, fn {xr, yr}, m ->
    reduce(xr, m, fn x, m ->
      reduce(yr, m, fn y, m ->
        Map.put(m, {x, y}, clay)
      end)
    end)
  end)
  |> Map.put(spring_coord, spring)
  |> simulate.(max_y)

#first

grid
 |> filter(fn {{_, y}, s} -> y >= min_y && y <= max_y && s in [static_water, flowing_water] end)
 |> count
 |> p

#second

grid
|> filter(fn {{_, y}, s} -> y >= min_y && y <= max_y && s in [static_water] end)
|> count
|> p
