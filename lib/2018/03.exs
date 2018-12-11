use DataStructures

regex_for_numbers = ~r"\d+"

claims =
  "inputs/03"
  |> In.f()
  |> map(fn claim ->
    [id, xs, ys, xl, yl] = Regex.scan(regex_for_numbers, claim) |> map(&(&1 |> hd |> Str.to_integer))
    {id, xs..(xs + xl - 1), ys..(ys + yl - 1)}
  end)

grid = A.new2d(1000, 1000, [])
grid = claims |> reduce(grid, fn {id, x, y}, acc -> update_in acc[{x, y}], &([id | &1]) end)

#first

f = &(len(&1) > 1)
map(grid, &(count(&1, f))) |> sum |> p

#second

filter(claims, fn {id, x, y} -> grid[{x, y}] |> uniq === [id] end) |> hd |> elem(0) |> p
