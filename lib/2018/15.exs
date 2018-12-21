use DataStructures

input =
  "inputs/15"
  |> In.f(column: "")

goblin = "G"
open = "."
elf = "E"
init_hp = 200

tests = [
  {
    """
    #########
    #G......#
    #.E.#...#
    #..##..G#
    #...##..#
    #...#...#
    #.G...G.#
    #.....G.#
    #########
    """,
    18740
  },
  {
    """
    #######
    #.E...#
    #.#..G#
    #.###.#
    #E#G#G#
    #...#G#
    #######
    """,
    28944
  },
  {
    """
    #######
    #E.G#.#
    #.#G..#
    #G.#.G#
    #G..#.#
    #...E.#
    #######
    """,
    27755
  },
  {
    """
    #######
    #E..EG#
    #.#G.E#
    #E.##E#
    #G..#.#
    #..E#.#
    #######
    """,
    39514
  },
  {
    """
    #######
    #G..#E#
    #E#E.E#
    #G.##.#
    #...#E#
    #...E.#
    #######
    """,
    36334
  }
]

build_input = fn input ->
  grid = input |> A.new
  fighters = (for i <- 0..len(grid), do: for j <- 0..len(grid[0]), grid[i][j] in [goblin, elf], do: {{i, j}, {init_hp, "#{grid[i][j]}#{i}#{j}"}}) |> List.flatten |> into(%{})
  {fighters, grid}
end

neighbours = fn {i, j} ->
  [
    {i - 1, j},
    {i, j - 1},
    {i, j + 1},
    {i + 1, j}
  ]
end

manhattan = fn {i1, j1}, {i2, j2} -> abs(i1 - i2) + abs(j1 - j2) end
neighbour? = fn {pos1, _}, {pos2, _} -> manhattan.(pos1, pos2) === 1 end

open? = fn grid -> fn idx -> grid[idx] === open end end

display = fn grid, fighters ->
  grid =
    grid
    |> map(&join/1)
    |> with_index
    |> map(fn {line, idx} ->
      f =
        fighters
        |> filter(fn {{i, _}, _} -> idx === i end)
        |> sort()
        |> map(fn {pos, {hp, id}} -> "#{id}(#{hp})" end)
        |> join(", ")
      "#{line}   #{f}"
    end)
    |> join("\n")
    |> IO.puts
end

find_dist_rec = fix fn f ->
  fn {srcs, dest, grid, dist, visited} ->
    cond do
      srcs === [] ->
        []
      #any?(srcs, fn src -> src === dest end) ->
       # dist
      any?(srcs, fn {n, _src} -> manhattan.(n, dest) === 1 end) ->
        srcs
        |> filter(fn {n, _src} -> manhattan.(n, dest) === 1 end)
        |> map(fn {n, src} -> {n, src, dist + 1} end)
      true ->
        next =
          srcs
          |> map(fn {cur, src} ->
            neighbours.(cur)
            |> filter(open?.(grid))
            |> filter(fn x -> !S.member?(visited, x) end)
            |> map(fn n -> {n, src} end)
          end)
          |> List.flatten
          |> uniq
        visited = next |> map(fn {n, _} -> n end) |> S.new |> S.union(visited)
        f.({next, dest, grid, dist + 1, visited})
    end
  end
end

find_dist = fn src, dest, grid ->
  srcs = neighbours.(src) |> filter(open?.(grid))
  srcs1 = srcs |> map(fn src -> {src, src} end)
  find_dist_rec.({srcs1, dest, grid, 0, S.new(srcs)})
end

find_targets = fn fighters, grid, type, cur_pos ->
  fighters
  |> filter(fn {pos, _} ->
    grid[pos] !== type
  end)
end

find_next = fn targets, grid, cur_pos ->
  targets =
    targets
    |> map(fn {pos, _} = target ->
      find_dist.(cur_pos, pos, grid)
      |> map(fn {dest, next, dist} -> {dist, dest, next, target} end)
    end)
    |> List.flatten
  {min_dist, _, _, _} = targets |> min_by(fn {d, _, _, _} -> d end, fn -> {nil, nil, nil, nil} end)
  targets
  |> filter(fn {d, _, _, _} -> d === min_dist end)
  |> map(fn {_, dest, next, target} -> {dest, next, target} end)
end

move = fn {{fighters, grid}, {pos, _} = fighter} ->
  type = grid[pos]
  value = fighters[pos]
  targets = find_targets.(fighters, grid, type, pos)
  if any?(targets, &neighbour?.(fighter, &1)) do
    {{fighters, grid}, fighter}
  else
    nearest =
      targets
      |> find_next.(grid, pos)
      |> sort
    if len(nearest) > 0 do
      {_, next, _} = hd(nearest)
      {{
        fighters |> Map.delete(pos) |> Map.put(next, value),
        grid |> put_in([pos], open) |> put_in([next], type)
      }, {next, value}}
    else
      {{fighters, grid}, fighter}
    end
  end
end

attack = fn {{fighters, grid}, {pos, _}} ->
  type = grid[pos]
  targets =
    pos
    |> neighbours.()
    |> filter(fn n -> Map.has_key?(fighters, n) && grid[n] !== type end)
    |> map(fn n ->
      {hp, id} = fighters[n]
      {hp, n, id}
    end)
  if empty?(targets) do
    {fighters, grid}
  else
    {hp, target_pos, target_id} = targets |> sort |> hd
    new_hp = hp - G.get(:aps)[type]
    if new_hp <= 0 do
      {Map.delete(fighters, target_pos), put_in(grid[target_pos], open)}
    else
      map = Map.put(fighters, target_pos, {new_hp, target_id})
      if target_id === "E1610" do
        IO.inspect(map)
      end
      {map, grid}
    end
  end
end

simulate_round = fn {old_fighters, _} = fighters_and_grid ->
  old_fighters
  |> sort_by(fn {pos, _} -> pos end)
  |> reduce(fighters_and_grid, fn {pos, _} = fighter, {fighters, grid} = fighters_and_grid ->
    l = fighters |> filter(fn {_, {_, id}} -> id === "E1610" end)
    IO.puts("#{inspect(pos)} -> #{inspect(l)}")
    if elem(Map.get(fighters, pos, {nil, nil}), 1) === elem(old_fighters[pos], 1) do
      {fighters_and_grid, fighter}
      |> move.()
      |> attack.()
    else
      {fighters, grid}
    end
  end)
end

no_goblin? = fn fighters, grid -> !any?(fighters, fn {pos, _} -> grid[pos] === goblin end) end
no_elf? = fn fighters, grid -> !any?(fighters, fn {pos, _} -> grid[pos] === elf end) end

simulate1 = fn {fighters, grid} ->
  loop({0, fighters, grid}, fn {round_nr, fighters, grid} ->
    #p(round_nr)
    #display.(grid, fighters)
    if no_elf?.(fighters, grid) || no_goblin?.(fighters, grid) do
      p(round_nr)
      display.(grid, fighters)
      hps = map(fighters, fn {_, {hp, _}} -> hp end)
      throw((round_nr - 1) * sum(hps))
    end
    {new_fighters, new_grid} = simulate_round.({fighters, grid})
    {round_nr + 1, new_fighters, new_grid}
  end)
end

run_tests = fn ->
  tests
  |> each(fn {input, expected} ->
    G.set(:aps, %{goblin => 3, elf => 3})
    got = input |> In.string(column: "") |> build_input.() |> simulate1.()
    if got !== expected do
      throw("Got #{got}, expected #{expected}")
    end
  end)
  IO.puts("Tests passed")
end


#run_tests.()

input = input |> build_input.()

# first

G.set(:aps, %{goblin => 3, elf => 3})
#input |> simulate1.() |> p


# second
nr_elf = fn fighters, grid -> count(fighters, fn {pos, _} -> grid[pos] === elf end) end
simulate2 = fn {fighters, grid} ->
  loop({0, fighters, grid}, fn {round_nr, fighters, grid} ->
    p(round_nr)
    display.(grid, fighters)
    if no_goblin?.(fighters, grid) do
      hps = map(fighters, fn {_, {hp, _}} -> hp end)
      throw((round_nr - 1) * sum(hps))
    end
    {new_fighters, new_grid} = simulate_round.({fighters, grid})
    if nr_elf.(fighters, grid) !== nr_elf.(new_fighters, new_grid) do
      throw(:failed)
    end
    {round_nr + 1, new_fighters, new_grid}
  end)
end

loop(15, fn elf_ap ->
   G.set(:aps, %{goblin => 3, elf => elf_ap})
   res = input |> simulate2.()
   if res !== :failed do
     throw({elf_ap, res})
   end
   elf_ap + 1
 end)
 |> p
