use DataStructures

[depth, target] =
  "inputs/22"
  |> In.f(column: ": ")
  |> map(fn [_, n] -> n end)

rocky = "."
narrow = "|"
wet = "="

depth = depth |> to_i
{targetx, targety} = target =
  target |> Str.split(",") |> map(&to_i/1) |> List.to_tuple

defmodule Assert do

  def create_fn(name) do
    fn input, got, expected ->
      if got !== expected do
        raise("For #{name}(#{inspect(input)}) = #{inspect(got)}, expected: #{inspect(expected)}")
      end
    end
  end

end

to_string = fn map ->
  maxx = len(map) - 1
  maxy = len(map[0]) - 1
  for y <- 0..maxy do
    for x <- 0..maxx do
      map[{x, y}] || ""
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

compute_grid = fn depth, target, {maxx, maxy} ->
  compute_geologic_index = fn
    {0, 0}, _ -> 0
    ^target, _ -> 0
    {x, 0}, _ -> x * 16807
    {0, y}, _ -> y * 48271
    {x, y}, grid -> grid[{x - 1, y}] * grid[{x, y - 1}]
  end

  compute_erosion_level = fn geologic_index ->
    rem(geologic_index + depth, 20183)
  end

  compute_type = fn erosion_level ->
    case rem(erosion_level, 3) do
      0 -> rocky
      1 -> wet
      2 -> narrow
    end
  end
  grid = A.new2d(maxx + 1, maxy + 1)
  grid =
    reduce(0..maxx, grid, fn x, grid ->
      reduce(0..maxy, grid, fn y, grid ->
        type =
          {x, y}
          |> compute_geologic_index.(grid)
          |> compute_erosion_level.()
        put_in(grid[{x, y}], type)
      end)
    end)
  grid
  |> A.map_rec(fn _, g_index ->
    g_index
    |> compute_type.()
  end)
  |> put_in([{0, 0}], "M")
  |> put_in([target], "T")
end

compute_risk_level = fn grid ->
  reduce(0..targetx, 0, fn x, s ->
    reduce(0..targety, s, fn y, s ->
      case grid[{x, y}] do
        s when s in ["M", "T", rocky] -> 0
        ^wet -> 1
        ^narrow -> 2
      end
      |> Kernel.+(s)
    end)
  end)
end

# first

compute_grid.(depth, target, target) |> compute_risk_level.() |> p


# second

defmodule FastestPathFinder do
  @rocky "."
  @narrow "|"
  @wet "="
  @time_to_change_tool 6

  @common_tools %{
    {@rocky, @narrow} => :t,
    {@narrow, @rocky} => :t,
    {@rocky, @wet} => :cg,
    {@wet, @rocky} => :cg,
    {@wet, @narrow} => :n,
    {@narrow, @wet} => :n
  }

  alias __MODULE__

  defmodule Pos do
    defstruct [:coord, :tool, :time]
  end

  def get_time(grid, target) do
    grid =
      grid
      |> put_in([target], @rocky)
      |> into([])
      |> map(&into(&1, []))
      |> A.new
    start_coord = {0, 0}
    can_use_tool? = fn pos, tool ->
      case {grid[pos], tool} do
        {@rocky, t} when t in [:cg, :t] -> true
        {@wet, t} when t in [:cg, :n] -> true
        {@narrow, t} when t in [:t, :n] -> true
        _ -> false
      end
    end
    filter_visited = fn %Pos{coord: c, tool: t}, visited, cur_time ->
      m = Map.get(visited, c, %{})
      best_time = m |> map(fn {_, time} -> time end) |> Enum.min(fn -> cur_time end)
      m[t] === nil && (cur_time - best_time) <= @time_to_change_tool
    end
    process_position = fn
      %Pos{coord: ^target, tool: t, time: 0}, _, _ when t !== :t ->
        [%Pos{coord: target, tool: :t, time: @time_to_change_tool}]
      %Pos{coord: ^start_coord, tool: t, time: 0}, _, _ ->
        {same, diff} =
          [{0, 1}, {1, 0}]
          |> split_with(fn n -> can_use_tool?.(n, t) end)
        same
        |> map(&(%Pos{coord: &1, tool: t, time: 0}))
        |> Kernel.++(
          diff |> map(fn c ->
          [
            %Pos{coord: c, tool: :n, time: @time_to_change_tool + 1},
            %Pos{coord: c, tool: :cg, time: @time_to_change_tool + 1},
          ]
          end)
          |> List.flatten
        )
      %Pos{coord: c, tool: t, time: 0}, visited, cur_time ->
        {same, diff} =
          neighbours(c)
          |> filter(&(grid[&1] !== nil && &1 !== start_coord))
          |> split_with(fn n -> can_use_tool?.(n, t) end)
        Kernel.++(
          same
          |> map(&(%Pos{coord: &1, tool: t, time: 0}))
          |> filter(&filter_visited.(&1, visited, cur_time)),
          diff
          |> map(&(%Pos{coord: &1, tool: @common_tools |> Map.fetch!({grid[c], grid[&1]}), time: @time_to_change_tool + 1}))
          |> filter(&filter_visited.(&1, visited, cur_time))
        )
      %Pos{time: time} = pos, _, _ when time > 0 ->
        [%{pos | time: time - 1}]
    end
    compute_fastest_path = fix fn f ->
      fn
        {positions, visited, time} ->
          cond do
            any?(positions, &(&1.coord === target && &1.tool === :t && &1.time === 0)) ->
              time
            true ->
              visited =
              positions
                |> filter(&(&1.time === 0))
                |> reduce(visited, fn %Pos{coord: c, tool: tool}, visited ->
                   m =
                     Map.get(visited, c, %{})
                     |> Map.put(tool, time)
                   Map.put(visited, c, m)
                end)
              new_positions =
                positions
                |> reduce([], &(&2 ++ process_position.(&1, visited, time)))
                |> uniq_by(&{&1.coord, &1.tool, &1.time})
              f.({new_positions, visited, time + 1})
        end
      end
    end
    start_pos = %Pos{coord: start_coord, tool: :t, time: 0}
    compute_fastest_path.({[start_pos], %{}, 0})
  end

  def test_get_time(compute_grid) do
    assert = Assert.create_fn("get_time")
    tests(compute_grid)
    |> with_index
    |> each(fn {{grid, target, expected}, idx} ->
      got = FastestPathFinder.get_time(grid, target)
      assert.({idx, target}, got, expected)
    end)
  end

  defp tests(compute_grid) do
    [
      {compute_grid.(510, {10, 10}, {15, 15}), {10, 10}, 45},
      # M=.
      # ..=
      # ..T
      {compute_grid.(0, {2, 2}, {2, 2}), {2, 2}, 4},
      {
        [
          ["M", "=", ".", "|", "."],
          [".", "=", ".", "=", "|"],
          [".", "=", ".", "=", "|"],
          [".", "=", ".", "=", "|"],
          [".", ".", ".", "=", "|"],
        ] |> A.new, {0, 4}, 12
      }
    ]
  end

  defp neighbours({x, y}) do
    [
      {x - 1, y},
      {x, y - 1},
      {x, y + 1},
      {x + 1, y}
    ]
  end
end

grid = compute_grid.(depth, target, {targetx + 45, targety})

FastestPathFinder.test_get_time(compute_grid)
FastestPathFinder.get_time(grid, target) |> p
