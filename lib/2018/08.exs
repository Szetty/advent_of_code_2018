use DataStructures

data =
  "inputs/08"
  |> In.f(column: " ")
  |> hd
  |> map(&to_i/1)


f = fix fn f ->
  fn
    {[], %Stack{elements: []}, nodes, _} ->
      nodes
    {input, %Stack{elements: []} = stack, nodes, node_nr} ->
      {[child_nr, metadata_nr], tail} = Enum.split(input, 2)
      stack = St.push(stack, {node_nr, child_nr, [], metadata_nr})
      f.({tail, stack, nodes, node_nr + 1})
    {input, stack, nodes, node_nr} ->
      {node, stack} = Stack.pop(stack)
      case node do
        {nr, 0, children, metadata_nr} ->
          {metadata, tail} = Enum.split(input, metadata_nr)
          node = {nr, children, metadata}
          stack = if !Stack.is_empty?(stack) do
            {{parent_nr, parent_children_nr, parent_children, parent_metadata_nr}, stack} = Stack.pop(stack)
            Stack.push(stack, {parent_nr, parent_children_nr - 1, [nr | parent_children], parent_metadata_nr})
          else
            stack
          end
          f.({tail, stack, [node | nodes], node_nr})
        {_nr, rem_child_nr, _children, _metadata_nr} when rem_child_nr > 0 ->
          {[child_nr, child_metadata_nr], tail} = Enum.split(input, 2)
          stack =
            stack
            |> Stack.push(node)
            |> Stack.push({node_nr, child_nr, [], child_metadata_nr})
          f.({tail, stack, nodes, node_nr + 1})
      end
  end
end


nodes = f.({data, St.new, [], 0})

#first

map(nodes, fn {_, _, metadata} -> sum(metadata) end) |> sum |> p

#second

loop({%{}, nodes}, fn {values, remaining_nodes} ->
  if empty?(remaining_nodes) do
    throw(values)
  end
  {to_compute, remaining_nodes} = split_with(remaining_nodes, fn {_, children, _} -> all?(children, &Map.has_key?(values, &1)) end)
  values =
    reduce(to_compute, values, fn {nr, children, metadata}, m ->
      value = if children === [] do
          sum(metadata)
        else
          children = [nil | (children |> reverse)] |> A.new # nil to ignore index 0
          metadata
          |> map(&Map.get(values, children[&1], 0))
          |> sum
        end
      Map.put(m, nr, value)
    end)
  {values, remaining_nodes}
end)
|> Map.get(0)
|> p
