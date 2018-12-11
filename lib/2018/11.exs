use DataStructures

gsn =
  "inputs/11"
  |> In.f()
  |> hd
  |> to_i

size = 300

f = fn x, y ->
  rid = x + 10
  rid
  |> Kernel.*(y)
  |> Kernel.+(gsn)
  |> Kernel.*(rid)
  |> Kernel./(100)
  |> to_i
  |> rem(10)
  |> Kernel.-(5)
end

sums = Algos.partial_sums(size, size, f)
area = fn x, y, s -> sums.calc.(x..(x + s), y..(y + s)) end
grid = range2d(1..size, 1..size)

#first

grid
 |> max_by(fn {x, y} -> area.(x, y, 2) end)
 |> p

#second

grid
|> map(fn {x, y} -> 1..size |> map(&{x, y, &1}) end)
|> List.flatten
|> max_by(fn {x, y, s} -> area.(x, y, s - 1) end)
|> p
