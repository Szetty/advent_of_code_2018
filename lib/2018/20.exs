use DataStructures

input =
  "inputs/20"
  |> In.f()
  |> hd()

assert_fn = fn name ->
  fn input, got, expected ->
    if got !== expected do
      raise("For #{name}(#{input}) = #{inspect(got)}, expected: #{inspect(expected)}")
    end
  end
end

neighbours = fn {i, j} ->
  [
    {i - 1, j},
    {i, j - 1},
    {i, j + 1},
    {i + 1, j}
  ]
end

diagonals = fn {x, y} ->
  [
    {x - 1, y - 1},
    {x + 1, y + 1},
    {x - 1, y + 1},
    {x + 1, y - 1}
  ]
end

compass = %{
  "N" => {-1, 0},
  "S" => {1, 0},
  "W" => {0, -1},
  "E" => {0, 1},
}

door_types = %{
  "N" => "-",
  "S" => "-",
  "W" => "|",
  "E" => "|",
}

add_direction = fn {x, y}, {dx, dy} -> {x + dx, y + dy} end

find_route = fix fn f ->
  fn
    {["(" | tail], st} -> f.({tail, [{[]} | st]})
    {[")" | tail], [x]} -> {x, tail}
    {[")" | tail], [x, {els} | st]} -> f.({tail, [{els ++ [x]} | st]})
    {[")" | tail], [x, {els1, els2} | st]} -> f.({tail, [{els1, els2 ++ [x]} | st]})
    {[")" | tail], [x, {els1, els2, els3} | st]} -> f.({tail, [{els1, els2, els3 ++ [x]} | st]})
    {["|" | tail], [x | st]} -> f.({tail, [Tuple.append(x, []) | st]})
    {[h | tail], [{els} | st]} -> f.({tail, [{els ++ [h]} | st]})
    {[h | tail], [{els1, els2} | st]} -> f.({tail, [{els1, els2 ++ [h]} | st]})
    {[h | tail], [{els1, els2, els3} | st]} -> f.({tail, [{els1, els2, els3 ++ [h]} | st]})
  end
end

test_find_route_end = fn ->
  assert = assert_fn.("find_route_end")
  tests = [
    {"(E|N)A", {{["E"], ["N"]}, ["A"]}},
    {"(E|N)W", {{["E"], ["N"]}, ["W"]}},
    {"(EE|N)W", {{["E", "E"], ["N"]}, ["W"]}},
    {"(EE|N)(W|N)", {{["E", "E"], ["N"]}, ["(", "W", "|", "N", ")"]}},
    {"(NEEE|SSE(EE|N))A", {{["N", "E", "E", "E"], ["S", "S", "E", {["E", "E"], ["N"]}]}, ["A"]}},
    {"(NEEE|SSE(EE|))A", {{["N", "E", "E", "E"], ["S", "S", "E", {["E", "E"], []}]}, ["A"]}},
    {"(A|B|C)$", {{["A"], ["B"], ["C"]}, ["$"]}},
    {"((1|2)|(3|4)|(5|6))$", {{[{["1"],["2"]}], [{["3"],["4"]}], [{["5"], ["6"]}]}, ["$"]}},
  ]
  each(tests, fn {input, expected} ->
    input = input |> Str.codepoints
    got = find_route.({input, []})
    assert.(input, got, expected)
  end)
end

parse = fix fn f ->
  fn
    ["$"] -> []
    [h | t] = input ->
      {res, tail} =
        case h do
          dir when dir in ["W", "S", "N", "E"] -> {dir, t}
          "(" -> find_route.({input, []})
        end
      [res | f.(tail)]
  end
end

put_door = fn map, pos, dir -> Map.put(map, pos, door_types[dir]) end
put_room = fn map, pos -> Map.put(map, pos, ".") end
put_walls = fn map, room_pos ->
  room_pos
  |> diagonals.()
  |> reduce(map, &Map.put_new(&2, &1, "#"))
end
put_unknown = fn map, next_pos, door_pos ->
  next_pos
  |> neighbours.()
  |> filter(fn n -> n !== door_pos end)
  |> reduce(map, &Map.put_new(&2, &1, "?"))
end

to_string = fn map ->
  {mini, maxi} = Enum.map(map, fn {{i, _}, _} -> i end) |> min_max
  {minj, maxj} = Enum.map(map, fn {{_, j}, _} -> j end) |> min_max
  for i <- mini..maxi do
    for j <- minj..maxj do
      map[{i, j}] || " "
    end
  end
  |> Enum.map(&join/1)
  |> join("\n")
end

display = fn map ->
  map
  |> to_string.()
  |> IO.puts
end

process_position = fn pos, dir, map ->
  direction = compass[dir]
  door_pos = add_direction.(pos, direction)
  room_pos = add_direction.(door_pos, direction)
  map =
    map
    |> put_door.(door_pos, dir)
    |> put_room.(room_pos)
    |> put_walls.(room_pos)
    |> put_unknown.(room_pos, door_pos)
  {room_pos, map}
end

process_directions = fix fn f ->
  fn
    {[], pos, map} ->
      {pos, map}

    {[dir | directions], positions, map} when is_binary(dir) ->
      {new_positions, map} =
        reduce(positions, {[], map}, fn pos, {positions, map} ->
          {new_pos, map} = process_position.(pos, dir, map)
          {[new_pos | positions], map}
        end)
      f.({directions, new_positions |> uniq, map})

    {[dir | directions], pos, map} when is_list(dir) ->
      {pos, map} =
        dir
        |> reduce({pos, map}, fn dir, {pos, map} -> f.({dir, pos, map}) end)
      f.({directions, pos, map})

    {[dir | directions], pos, map} when is_tuple(dir) ->
      {pos, map} =
        dir
        |> Tuple.to_list()
        |> reduce({[], map}, fn dirs, {positions, map} ->
          {new_pos, map} = f.({dirs, pos, map})
          {positions ++ new_pos, map}
        end)
      f.({directions, pos |> uniq, map})
  end
end

start_pos = {0, 0}
start_map =
  %{}
  |> Map.put(start_pos, "X")
  |> put_unknown.(start_pos, nil)
  |> put_walls.(start_pos)


draw_map = fn input ->
  directions = input
  |> Str.trim("^")
  |> Str.codepoints
  |> parse.()
  {_, map} = process_directions.({directions, [start_pos], start_map})
  map |> Enum.map(fn {pos, value} ->
    if value === "?" do
      {pos, "#"}
    else
      {pos, value}
    end
  end)
  |> into(%{})
end

test_draw_map = fn ->
  assert = assert_fn.("draw_map")
  tests = [
    {
      "^ENWWW(NEEE|SSE(EE|N))$",
      """
      #########
      #.|.|.|.#
      #-#######
      #.|.|.|.#
      #-#####-#
      #.#.#X|.#
      #-#-#####
      #.|.|.|.#
      #########
      """
    },
    {
      "^ENNWSWW(NEWS|)SSSEEN(WNSE|)EE(SWEN|)NNN$",
      """
      ###########
      #.|.#.|.#.#
      #-###-#-#-#
      #.|.|.#.#.#
      #-#####-#-#
      #.#.#X|.#.#
      #-#-#####-#
      #.#.|.|.|.#
      #-###-###-#
      #.|.|.#.|.#
      ###########
      """
    },
    {
      "^ESSWWN(E|NNENN(EESS(WNSE|)SSS|WWWSSSSE(SW|NNNE)))$",
      """
      #############
      #.|.|.|.|.|.#
      #-#####-###-#
      #.#.|.#.#.#.#
      #-#-###-#-#-#
      #.#.#.|.#.|.#
      #-#-#-#####-#
      #.#.#.#X|.#.#
      #-#-#-###-#-#
      #.|.#.|.#.#.#
      ###-#-###-#-#
      #.|.#.|.|.#.#
      #############
      """
    },
    {
      "^WSSEESWWWNW(S|NENNEEEENN(ESSSSW(NWSW|SSEN)|WSWWN(E|WWS(E|SS))))$",
      """
      ###############
      #.|.|.|.#.|.|.#
      #-###-###-#-#-#
      #.|.#.|.|.#.#.#
      #-#########-#-#
      #.#.|.|.|.|.#.#
      #-#-#########-#
      #.#.#.|X#.|.#.#
      ###-#-###-#-#-#
      #.|.#.#.|.#.|.#
      #-###-#####-###
      #.|.#.|.|.#.#.#
      #-#-#####-#-#-#
      #.#.|.|.|.#.|.#
      ###############
      """
    }
  ]
  each(tests, fn {input, expected} ->
    got = draw_map.(input) |> to_string.()
    try do
      assert.(input, got |> Str.trim, expected |> Str.trim)
    rescue
      e in RuntimeError ->
        IO.puts(e.message)
        IO.puts("Got:\n" <> got)
        IO.puts("Expected:\n" <> expected)
    end
  end)
end

calculate_paths = fn map ->
  rooms = filter(map, fn {_, v} -> v === "." end) |> into(%{})
  loop({[start_pos], rooms, 1}, fn {positions, rooms, dist} ->
    if !any?(rooms, fn {_, v} -> v === "." end) do
      throw(rooms)
    end
    {new_positions, rooms} =
      positions
      |> Enum.reduce({[], rooms}, fn pos, {positions, rooms} ->
        next_positions =
          pos
          |> neighbours.()
          |> filter(fn n -> map[n] === "|" || map[n] === "-" end)
          |> Enum.reduce([], fn door, positions ->
            door
            |> neighbours.()
            |> filter(fn n -> rooms[n] === "." && map[n] === "." end)
            |> Kernel.++(positions)
          end)

        rooms = reduce(next_positions, rooms, &Map.put(&2, &1, dist))
        {next_positions ++ positions, rooms}
      end)
    {new_positions |> uniq, rooms, dist + 1}
  end)
end

longest_path = fn map ->
  map |> calculate_paths.() |> Map.values |> max
end

test_calculate_paths = fn ->
  assert = assert_fn.("longest_path")
  tests = [
    {"^WNE$", 3},
    {"^ENWWW(NEEE|SSE(EE|N))$", 10},
    {"^ENNWSWW(NEWS|)SSSEEN(WNSE|)EE(SWEN|)NNN$", 18},
    {"^ESSWWN(E|NNENN(EESS(WNSE|)SSS|WWWSSSSE(SW|NNNE)))$", 23},
    {"^WSSEESWWWNW(S|NENNEEEENN(ESSSSW(NWSW|SSEN)|WSWWN(E|WWS(E|SS))))$", 31}
  ]
  each(tests, fn {input, expected} ->
    map = draw_map.(input)
    #display.(map)
    got = map |> longest_path.()
    assert.(input, got, expected)
  end)
end

test_find_route_end.()
test_draw_map.()
test_calculate_paths.()

# first

draw_map.(input) |> longest_path.() |> p

# second

draw_map.(input) |> calculate_paths.() |> count(fn {_, d} -> d >= 1000 end) |> p
