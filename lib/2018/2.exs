use DataStructures

words =
  "inputs/2"
  |> In.f()
  |> map(&Str.graphemes/1)


# first

{two_counts, three_counts} =
  words
  |> map(fn word -> group_by(word, identity()) |> Map.values() |> map(&len/1) end)
  |> reduce({0, 0}, fn counts, {two, three} ->
    f2 = if member?(counts, 2), do: 1, else: 0
    f3 = if member?(counts, 3), do: 1, else: 0
    {two + f2, three + f3}
  end)

(two_counts * three_counts) |> p

# second

for word1 <- words do
    for word2 <- words do
      if word1
      |> zip(word2)
      |> Enum.count(fn {c1, c2} -> c1 !== c2 end) === 1 do
        word1
        |> join
        |> Str.myers_difference(word2 |> join)
        |> KW.get_values(:eq)
        |> join
        |> p
        exit()
      end
    end
end
