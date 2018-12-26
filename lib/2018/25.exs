use DataStructures

input =
  "inputs/25"
  |> In.f(column: ",")
  |> map(fn l -> map(l, &to_i/1) |> List.to_tuple end)

manhattan = fn {x1, y1, z1, t1}, {x2, y2, z2, t2} ->
  abs(x1 - x2) + abs(y1 - y2) + abs(z1 - z2) + abs(t1 - t2)
end

find_constellations = fix fn f ->
  fn
    {[], c} -> c
    {[p], c} -> [[p] | c]
    {[p | points], c} ->
      {close, far} = split_with(points, fn p1 -> manhattan.(p, p1) <= 3 end)
      c = [[p | close] | c]
      f.({far, c})
  end
end

do_combine_constellations = fix fn f->
  fn
    {[], c} -> c
    {[c], cs} -> [c | cs]
    {[c | cs], new_cs} ->
      {sim, diff} = split_with(cs, fn c1 -> any?(c1, fn p -> any?(c, &(manhattan.(&1, p) <= 3)) end) end)
      c = c ++ List.flatten(sim)
      f.({diff, [c | new_cs]})
  end
end

combine_constellations = fn c ->
  loop(c, fn c ->
    new_c = do_combine_constellations.({c, []})
    if len(c) === len(new_c) do
      throw(new_c)
    end
    new_c
  end)
end

find_constellations.({input, []})
|> combine_constellations.()
|> len
|> p
