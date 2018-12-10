use DataStructures

man  = fn {x1, y1}, {x2, y2} -> abs(x2 - x1) + abs(y2 - y1) end

data =
  "inputs/6"
  |> In.f(column: ",")
  |> map(fn [x, y] -> {x |> Str.to_integer, y |> Str.trim |> Str.to_integer} end)

{minx, maxx} = data |> map(fn {x, _} -> x end) |> min_max
{miny, maxy} = data |> map(fn {_, y} -> y end) |> min_max

grid = (for x <- minx..maxx, do: for y <- miny..maxy, do: {x, y}) |> List.flatten

#first

infinites = [
  data |> min_by(fn p -> man.(p, {minx, miny}) end),
  data |> min_by(fn p -> man.(p, {minx, maxy}) end),
  data |> min_by(fn p -> man.(p, {maxx, miny}) end),
  data |> min_by(fn p -> man.(p, {maxx, maxy}) end),
]

grid |> map(fn {x, y} ->
  result =
    map(data, &({&1, man.(&1, {x,y})}))
    |> sort_by(fn {_, d} -> d end)
    |> take(2)
  case result do
    [{_, d}, {_, d}] -> []
    [{p1, _}, {_, _}] -> [p1]
  end
end)
|> List.flatten
|> group_by(identity(), fn _ -> 1 end)
|> map(fn {k, v} -> {k, len(v)} end)
|> filter(fn {k, _} -> !member?(infinites, k) end)
|> max_by(fn {_, v} -> v end)
|> elem(1)
|> p

#second

good? = fn p -> (data |> map(&(man.(&1, p)))) |> sum < 10000 end
grid |> filter(good?) |> len |> p
