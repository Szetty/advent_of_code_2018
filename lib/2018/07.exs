use DataStructures

data =
  "inputs/07"
  |> In.f()
  |> map(fn "Step " <> <<from::bytes-size(1)>> <> " must be finished before step " <> <<to::bytes-size(1)>> <> " can begin."->
    {from, to}
  end)

graph = Gr.new()
reduce(data, graph, fn {from, to}, graph ->
  graph
  |> Gr.vertex(from)
  |> Gr.vertex(to)
  |> Gr.edge(from <> to, {from, to})
end)

#first

Gr.topological_sort(graph) |> join |> p

#second

Gr.get_vertices(graph) |> each(fn v ->
  code = v |> String.to_charlist |> hd
  Gr.vertex(graph, v, 60 + code - ?A + 1)
end)
Gr.critical_path(graph) |> map(fn v -> Gr.get_vertex(graph, v) |> elem(1) end) |> sum |> p
