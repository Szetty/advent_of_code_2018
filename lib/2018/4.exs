use DataStructures

data =
  "inputs/4"
  |> In.f()
  |> sort
  |> map(fn s ->
    [d, t] = String.split(s, "]")
    d = Regex.scan(~r/\d+/, d) |> slice(-1..-1) |> List.flatten |> hd |> Str.to_integer
    {d, t |> Str.trim}
  end)

{m, _, _} = reduce(data, {%{}, nil, nil}, fn {d, t}, {map, last_id, last_d} ->
    case t do
      "Guard #" <> res ->
        id = res |> Str.split(" ") |> hd |> Str.to_integer
        map =
          if last_d !== nil do
            {l, v} = Map.get(map, last_id, {[], 0})
            Map.put(map, last_id, {[{last_d, d} | l], v + d - last_d})
          else
            map
          end
        {map, id, nil}
      "falls asleep" ->
        {map, last_id, d}
      "wakes up" ->
        {l, v} = Map.get(map, last_id, {[], 0})
        map = Map.put(map, last_id, {[{last_d, d} | l], v + d - last_d})
        {map, last_id, nil}
    end
  end)

f = &(fn {s, e} -> (s <= &1) && (&1 <= e) end)

#first

  {id, {l, _v}} = m |> max_by(fn {_key, {_l, v}} -> v end)
  {min, _} =
    0..59
    |> map(&({&1, count(l, f.(&1))}))
    |> max_by(fn {_min, c} -> c end)
  (id * min) |> p


#second

  {min, {id, _c}} =
    0..59
    |> map(&({
        &1,
        map(m, fn {key, {l, _v}} ->
          {key, count(l, f.(&1))}
        end)
        |> max_by(fn {_, c} -> c end)}))
    |> max_by(fn {_min, {_id, c}} -> c end)
  (id * min) |> p
