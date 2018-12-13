use DataStructures

cart_symbols = ["<", ">", "^", "v"]

data =
  "inputs/13"
  |> In.f()
  |> map(&String.codepoints/1)

G.set(:carts, %{})

extract_carts = fn {line, y} ->
  line
  |> with_index
  |> map(fn {cell, x} ->
    if member?(cart_symbols, cell) do
      carts = G.get(:carts) |> Map.put({x, y}, {cell, :l})
      G.set(:carts, carts)
    end
    case cell do
      ">" -> "-"
      "<" -> "-"
      "v" -> "|"
      "^" -> "|"
      _ -> cell
    end
  end)
end

grid =
  data
  |> with_index()
  |> map(extract_carts)
  |> A.new()

display = fn carts ->
  carts
  |> reduce(grid, fn {{x, y}, {cart, _}}, grid ->
    put_in grid[y][x], cart
  end)
  |> map(&join(&1, ""))
  |> join("\n")
  |> IO.puts
end

next_pos = fn cart, x, y ->
  case cart do
    ">" -> {x + 1, y}
    "<" -> {x - 1, y}
    "v" -> {x, y + 1}
    "^" -> {x, y - 1}
  end
end

next_state = fn cart, cell, next_dir ->
  case {cart, cell, next_dir} do
    {"<", "+", :l} -> {"v", :s}
    {"<", "+", :r} -> {"^", :l}
    {"<", "/", _} -> {"v", next_dir}
    {"<", "\\", _} -> {"^", next_dir}
    {">", "+", :l} -> {"^", :s}
    {">", "+", :r} -> {"v", :l}
    {">", "/", _} -> {"^", next_dir}
    {">", "\\", _} -> {"v", next_dir}
    {"^", "+", :l} -> {"<", :s}
    {"^", "+", :r} -> {">", :l}
    {"^", "/", _} -> {">", next_dir}
    {"^", "\\", _} -> {"<", next_dir}
    {"v", "+", :l} -> {">", :s}
    {"v", "+", :r} -> {"<", :l}
    {"v", "/", _} -> {"<", next_dir}
    {"v", "\\", _} -> {">", next_dir}
    {">", "-", _} -> {">", next_dir}
    {"<", "-", _} -> {"<", next_dir}
    {"^", "|", _} -> {"^", next_dir}
    {"v", "|", _} -> {"v", next_dir}
    {cart, "+", :s} -> {cart, :r}
  end
end

G.set(:first_crash, false)


second = fn carts ->
  carts =
    carts
    |> sort_by(fn {{x, y}, _v} -> {y, x} end)
    |> reduce(carts, fn {{x, y}, {cart, next_dir}}, carts ->
    if !Map.has_key?(carts, {x, y}) do
      carts
    else
      carts = Map.delete(carts, {x, y})
      {x, y} = next_pos.(cart, x, y)
      other_cart = Map.get(carts, {x, y})
      if other_cart !== nil do
        if !G.get(:first_crash) do
          IO.puts("#{x}, #{y}")
          G.set(:first_crash, true)
        end
        carts = Map.delete(carts, {x, y})
        carts
      else
        {cart, next_dir} = next_state.(cart, grid[y][x], next_dir)
        carts = Map.put(carts, {x, y}, {cart, next_dir})
        carts
      end
    end
  end)
  if map_size(carts) === 1 do
    throw(carts |> Map.keys |> hd)
  end
  carts
end

loop(G.get(:carts), second) |> p
