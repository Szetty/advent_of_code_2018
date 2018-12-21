use DataStructures
import Bitwise

input =
  "inputs/21"
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

[first | tail] = input
[_, initial_value] = Str.split(first, " ")
ip = to_i(initial_value)

operations =
  tail
  |> map(fn x ->
  [op, a, b,c ] = x |> Str.split(" ")
  {op, {to_i(a), to_i(b), to_i(c)}}
end)
  |> A.new()

  simulate = fn r, ip_v, r0 ->
    loop({%{r | 0 => r0}, ip_v}, fn {r, ip_v} ->
      if ip_v === 28  do
        throw(r[2])
      end
      {op, params} = operations[ip_v]
      r =
        %{r | (ip) => ip_v}
      |> ops[op].(params)
      {r, r[ip] + 1}
    end)
  end


r = 0..5 |> reduce(%{}, &Map.put(&2, &1, 0))

#first

simulate.(r, 0, 0) |> p

# second

simulate = fn r, ip_v, r0 ->
  loop({%{r | 0 => r0}, ip_v, S.new, nil}, fn {r, ip_v, visited, last} ->
    {visited, last} = if ip_v === 28 do
      if S.member?(visited, r[2]) do
        throw(last)
      else
        {S.put(visited, r[2]), r[2]}
      end
      else
        {visited, last}
    end
    {op, params} = operations[ip_v]
    r =
      %{r | (ip) => ip_v}
    |> ops[op].(params)
    {r, r[ip] + 1, visited, last}
  end)
end

simulate.(r, 0, 0) |> p
