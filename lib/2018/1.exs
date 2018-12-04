use DataStructures

changes =
  "inputs/1"
  |> In.f(to: :i)

#first

changes |> sum |> p

#second

{0, S.new}
|> loop(fn {f, s} ->
  reduce(changes, {f, s}, fn ch, {f, s} ->
    if S.member?(s, f), do: throw(f), else: {f + ch, S.put(s, f)}
  end)
end)
|> p
