use DataStructures

score_length = 10

data =
  "inputs/14"
  |> In.f()
  |> hd()
  |> to_i()

advance = fn recipes, cur_idx, shift ->
  rem(cur_idx + shift, len(recipes))
end

create_new_recipes = fn recipes, sum ->
  new_recipes = Integer.digits(sum)
  reduce(new_recipes, recipes, fn recipe, recipes ->
    put_in recipes[len(recipes)], recipe
  end)
end

calculate_score = fn recipes ->
  recipes
  |> slice(data..(data + score_length - 1))
  |> join
end

recipes = [3, 7] |> A.new

# first

loop({recipes, {0, 1}}, fn {recipes, {cur1, cur2}} ->
  if (len(recipes) >= data + score_length) do
    throw(calculate_score.(recipes))
  end
  recipes = create_new_recipes.(recipes, recipes[cur1] + recipes[cur2])
  cur1 = advance.(recipes, cur1, recipes[cur1] + 1)
  cur2 = advance.(recipes, cur2, recipes[cur2] + 1)
  {recipes, {cur1, cur2}}
end)
|> p

# second

digits = data |> Integer.digits

search_pattern = fix fn f ->
  fn
    {[], _} -> nil
    {l, _} when length(l) < length(digits) -> nil
    {[_h | t] = l, idx} ->
      digs = take(l, len(digits))
      if digs === digits do
        idx
      else
        f.({t, idx + 1})
      end
  end
end

loop({recipes, {0, 1}}, fn {recipes, {cur1, cur2}} ->
  index = search_pattern.({recipes |> slice((-len(digits) - 1)..-1), -len(digits) - 1})
  if (index !== nil) do
    throw(len(recipes) + index)
  end
  recipes = create_new_recipes.(recipes, recipes[cur1] + recipes[cur2])
  cur1 = advance.(recipes, cur1, recipes[cur1] + 1)
  cur2 = advance.(recipes, cur2, recipes[cur2] + 1)
  {recipes, {cur1, cur2}}
end)
|> p

