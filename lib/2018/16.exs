use DataStructures
use Bitwise, only_operators: true

ops = [
  fn r, {_, a, b, c} -> %{r | (c) => r[a] + r[b]}  end, # addr
  fn r, {_, a, b, c} -> %{r | (c) => r[a] + b} end, # addi
  fn r, {_, a, b, c} -> %{r | (c) => r[a] * r[b]} end, # mulr
  fn r, {_, a, b, c} -> %{r | (c) => r[a] * b} end, # muli
  fn r, {_, a, b, c} -> %{r | (c) => r[a] &&& r[b]} end, # banr
  fn r, {_, a, b, c} -> %{r | (c) => r[a] &&& b} end, # bani
  fn r, {_, a, b, c} -> %{r | (c) => r[a] ||| r[b]} end, # borr
  fn r, {_, a, b, c} -> %{r | (c) => r[a] ||| b} end, # bori
  fn r, {_, a, _b, c} -> %{r | (c) => r[a]} end, # setr
  fn r, {_, a, _b, c} -> %{r | (c) => a} end, # seti
  fn r, {_, a, b, c} -> %{r | (c) => (if a > r[b], do: 1, else: 0) } end, # gtir
  fn r, {_, a, b, c} -> %{r | (c) => (if r[a] > b, do: 1, else: 0) } end, # gtri
  fn r, {_, a, b, c} -> %{r | (c) => (if r[a] > r[b], do: 1, else: 0) } end, # gtrr
  fn r, {_, a, b, c} -> %{r | (c) => (if a === r[b], do: 1, else: 0) } end, # eqir
  fn r, {_, a, b, c} -> %{r | (c) => (if r[a] === b, do: 1, else: 0) } end, # eqri
  fn r, {_, a, b, c} -> %{r | (c) => (if r[a] === r[b], do: 1, else: 0) } end, # eqrr
]

data =
  "inputs/16"
  |> In.f()

last_after_index = len(data) - (data |> reverse |> find_index(fn x -> Str.starts_with?(x, "After:") end)) - 1

i = &to_i/1

first_mapper = fn ["Before: [" <> <<before_str::bytes-size(10)>> <> "]", instruction_str, "After:  [" <> <<after_str::bytes-size(10)>> <> "]"] ->
  registers_before = Str.split(before_str, ", ") |> with_index |> map(fn {e, idx} -> {idx, to_i(e)} end) |> into(%{})
  instruction = Str.split(instruction_str, " ") |> map(i) |> List.to_tuple
  registers_after = Str.split(after_str, ", ") |> with_index |> map(fn {e, idx} -> {idx, to_i(e)} end) |> into(%{})
  {registers_before, instruction, registers_after}
end

second_mapper = &(Str.split(&1, " ") |> map(i) |> List.to_tuple)

first = slice(data, 0..last_after_index) |> chunk_every(3) |> map(first_mapper)
second = slice(data, (last_after_index + 1)..-1) |> map(second_mapper)

# first

first
|> count(fn {rb, op, ra} ->
  count(ops, fn operation -> operation.(rb, op) === ra end) >= 3
end)
|> p

# second

with_potential_ops = fn {rb, {code, _, _, _} = op, ra} ->
  {
    code,
    ops
    |> with_index
    |> filter(fn {operation, _} -> operation.(rb, op) === ra end)
    |> map(fn {_, idx} -> idx end)
  }
end

code_with_ops =
  first
  |> map(with_potential_ops)


code_to_op_map = loop({code_with_ops, %{}}, fn {code_with_ops, code_to_op_map} ->
  if len(code_with_ops) === 0 do
    throw(code_to_op_map)
  end
  to_assoc = code_with_ops |> filter(fn {_, ops} -> len(ops) === 1 end) |> uniq
  not_associated_code? = fn {code, _} -> !any?(to_assoc, fn {c, _} -> code === c end) end
  not_associated_op? = fn op -> !any?(to_assoc, fn {_, [o]} -> o === op end) end
  code_to_op_map = reduce(to_assoc, code_to_op_map, fn {code, [op]}, m -> Map.put(m, code, op) end)
  code_with_ops =
    code_with_ops
    |> filter(not_associated_code?)
    |> map(fn {code, ops} -> {code, filter(ops, not_associated_op?)} end)
  {code_with_ops, code_to_op_map}
end)

code_to_op = fn code -> at(ops, code_to_op_map[code]) end

inital_registers = %{0 => 0, 1 => 0, 2 => 0, 3 => 0}
reduce(second, inital_registers, fn {code, _, _, _} = instr, r ->
  code_to_op.(code).(r, instr)
end)
|> Map.get(0)
|> p
