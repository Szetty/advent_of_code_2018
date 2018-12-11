use DataStructures

letters = for n <- ?a..?z, do: << n :: utf8 >>

data =
  "inputs/05"
  |> In.f()
  |> hd
  |> Str.graphemes

defmodule React do
  def run(l) do
    case l do
      [] -> []
      [_] = l -> l
      [h1, h2 | t] ->
        if h1 !== h2 && (Str.upcase(h1) === h2 || Str.upcase(h2) === h1) do
          a(t)
        else
          [h1 | a([h2 | t])]
        end
    end
  end
end

full_react = fn polymer ->
  loop(polymer, fn p ->
    new_p = React.run(p)
    if len(new_p) === len(p), do: throw(len(new_p))
    new_p
  end)
end

#first

data |> full_react.() |> p

#second

Parallel.map(letters, fn let -> data |> filter(&(&1 !== let && &1 !== Str.upcase(let))) |> full_react.() end)
|> min
|> p
