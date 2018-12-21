use DataStructures
import Bitwise

data =
  "inputs/19"
  |> In.f()

ops = %{
  "addr" => fn r, {a, b, c} -> %{r | (c) => r[a] + r[b]} end,
  "addi" => fn r, {a, b, c} -> %{r | (c) => r[a] + b} end,
  "mulr" => fn r, {a, b, c} -> %{r | (c) => r[a] * r[b]} end,
  "muli" => fn r, {a, b, c} -> %{r | (c) => r[a] * b} end,
  "banr" => fn r, {a, b, c} -> %{r | (c) => r[a] &&& r[b]} end,
  "bani" => fn r, {a, b, c} -> %{r | (c) => r[a] &&& b} end,
  "borr" => fn r, {a, b, c} -> %{r | (c) => r[a] ||| r[b]} end,
  "bori" => fn r, {a, b, c} -> %{r | (c) => r[a] ||| b} end,
  "setr" => fn r, {a, _b, c} -> %{r | (c) => r[a]} end,
  "seti" => fn r, {a, _b, c} -> %{r | (c) => a} end,
  "gtir" => fn r, {a, b, c} -> %{r | (c) => (if a > r[b], do: 1, else: 0) } end,
  "gtri" => fn r, {a, b, c} -> %{r | (c) => (if r[a] > b, do: 1, else: 0) } end,
  "gtrr" => fn r, {a, b, c} -> %{r | (c) => (if r[a] > r[b], do: 1, else: 0) } end,
  "eqir" => fn r, {a, b, c} -> %{r | (c) => (if a === r[b], do: 1, else: 0) } end,
  "eqri" => fn r, {a, b, c} -> %{r | (c) => (if r[a] === b, do: 1, else: 0) } end,
  "eqrr" => fn r, {a, b, c} -> %{r | (c) => (if r[a] === r[b], do: 1, else: 0) } end,
}


[first | tail] = data
[_, initial_value] = Str.split(first, " ")

operations =
  tail
  |> map(fn x ->
    [op, a, b,c ] = x |> Str.split(" ")
    {op, {to_i(a), to_i(b), to_i(c)}}
  end)
  |> A.new

ip = to_i(initial_value)
r = 0..5 |> reduce(%{}, &Map.put(&2, &1, 0))

simulate = fn r, ip_v ->
  loop({r, ip_v}, fn {r, ip_v} ->
  if (ip_v >= len(operations)) do
    throw(r[0])
  end
    {op, params} = operations[ip_v]
    r =
      %{r | (ip) => ip_v}
      |> ops[op].(params)
    {r, r[ip] + 1}
  end)
end

#first

simulate.(r, 0) |> p

# second

# sum of factors of number 10551331
[1, 7, 29, 203, 51977, 363839, 1507333, 10551331] |> Enum.sum |> p
