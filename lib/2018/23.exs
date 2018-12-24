use DataStructures

nanobots =
  "inputs/23"
  |> In.f()
  |> map(fn s ->
    [x, y, z, r] =
      Regex.scan(~r"-?\d+", s)
      |> map(&hd/1)
      |> map(&to_i/1)
    {{x, y, z}, r}
  end)
  |> into(%{})

assert_fn = fn name ->
    fn input, got, expected ->
      if got !== expected do
        raise("For #{name}(#{inspect(input)}) = #{inspect(got)}, expected: #{inspect(expected)}")
      end
    end
end

manhattan = fn {x1, y1, z1}, {x2, y2, z2} ->
    abs(x1 - x2) + abs(y1 - y2) + abs(z1 - z2)
end

bots_in_radius = fn nanobots, relative_pos, relative_r ->
  nanobots
  |> count(fn {pos, r} ->
    manhattan.(pos, relative_pos) <= if relative_r !== nil, do: relative_r, else: r
  end)
end

# first

{strongest_pos, strongest_r} =
    nanobots
    |> max_by(fn {_, r} -> r end)

bots_in_radius.(nanobots, strongest_pos, strongest_r)
|> p

# second

intersect_ranges = fn
  [], _ -> []
  _f1..l1, f2.._l2 when l1 < f2 -> []
  f1.._l1, _f2..l2 when l2 < f1 -> []
  f1..l1, f2..l2 -> (Kernel.max(f1, f2))..(Kernel.min(l1, l2))
end

test_intersect_ranges = fn ->
  assert = assert_fn.("intersect_ranges")
  tests = [
    {1..2, 3..4, []},
    {1..3, 2..4, 2..3},
    {2..4, 1..3, 2..3},
    {1..10, 3..7, 3..7},
    {3..7, 1..10, 3..7},
    {-5..-1, -7..-6, []},
    {0..4, 4..7, 4..4},
    {4..7, 0..4, 4..4},
    {[], 1..2, []},
  ]
  tests
  |> each(fn {input1, input2, expected} ->
    got = intersect_ranges.(input1, input2)
    assert.({input1, input2}, got, expected)
  end)
end

test_intersect_ranges.()

intersection = fn {xr1, yr1, zr1}, {xr2, yr2, zr2} ->
  xr = intersect_ranges.(xr1, xr2)
  yr = intersect_ranges.(yr1, yr2)
  zr = intersect_ranges.(zr1, zr2)
  {xr, yr, zr}
end

find_outliers = fn nanobots ->
  xr = -50_000_000..20_000_000
  yr = -10_000_000..30_000_000
  zr = -50_000_000..50_000_000
  outlierx =
    nanobots
    |> with_index()
    |> filter(fn {{{x, _, _}, r}, _idx} -> intersect_ranges.(xr, (x - r)..(x + r)) === [] end)
  |> map(fn {_, idx} -> idx end)
  outliery =
    nanobots
    |> with_index()
    |> filter(fn {{{_, y, _}, r}, _idx} -> intersect_ranges.(yr, (y - r)..(y + r)) === [] end)
  |> map(fn {_, idx} -> idx end)
  outlierz =
    nanobots
    |> with_index()
    |> filter(fn {{{_, _, z}, r}, _idx} -> intersect_ranges.(zr, (z - r)..(z + r)) === [] end)
  |> map(fn {_, idx} -> idx end)

  outlierx ++ outliery ++ outlierz
end

find_range = fn nanobots, outliers ->
  nanobots
  |> with_index
  |> filter(fn {_, idx} -> !member?(outliers, idx) end)
  |> map(fn {{{x, y, z}, r}, _} -> {(x - r)..(x + r), (y - r)..(y + r), (z - r)..(z + r)} end)
  |> reduce(fn posr, acc -> intersection.(acc, posr) end)
end

outliers = find_outliers.(nanobots)
find_range.(nanobots, outliers) |> p
max_nanobots = (len(nanobots) - len(outliers))

neighbours = fn {x, y, z}, step ->
  [
    {x - step, y - step, z - step},
    {x - step, y - step, z},
    {x - step, y, z - step},
    {x - step, y - step, z + step},
    {x - step, y + step, z - step},
    {x - step, y, z},
    {x - step, y + step, z},
    {x - step, y, z + step},
    {x - step, y + step, z + step},
    {x, y - step, z - step},
    {x, y - step, z},
    {x, y, z - step},
    {x, y - step, z + step},
    {x, y + step, z - step},
    {x, y, z},
    {x, y + step, z},
    {x, y, z + step},
    {x, y + step, z + step},
    {x + step, y - step, z - step},
    {x + step, y - step, z},
    {x + step, y, z - step},
    {x + step, y - step, z + step},
    {x + step, y + step, z - step},
    {x + step, y, z},
    {x + step, y + step, z},
    {x + step, y, z + step},
    {x + step, y + step, z + step},
  ]
end

{best_pos, best_count} =
  nanobots
  |> map(fn {pos, _} -> {pos, bots_in_radius.(nanobots, pos, nil)} end)
  |> max_by(fn {_, c} -> c end)

# Local maxima search
{x, y, z} = loop({best_pos, best_count, 5_000_000}, fn {best_pos, best_count, step} ->
  {new_best_pos, new_best_count} = loop({best_pos, best_count}, fn {position, count} ->
    {p, c} = position
    |> neighbours.(step)
    |> map(fn p ->
      {p, bots_in_radius.(nanobots, p, nil)}
    end)
    |> max_by(fn {_, c} -> c end)
    if c > count || (c === count && p < position) do
      {p, c}
    else
      throw({position, count})
    end
  end)
  if new_best_count === max_nanobots do
    throw(new_best_pos)
  end
  if new_best_count > best_count || new_best_count === best_count && new_best_pos < best_pos do
    {new_best_pos, new_best_count, (step / 1.34) |> round}
  else
    {best_pos, best_count, (step / 1.34) |> round}
  end
end)

(x + y + z) |> p
