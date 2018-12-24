use DataStructures

input =
  "inputs/24"
  |> In.f()

defmodule Group do
  defstruct [:nr, :hp, :ad, :at, :prio, :weak, :imun, :type]
end

defmodule Parser do
  @regex  ~r/(\d+) units each with (\d+) hit points(\s\([a-z\s,;]*\))? with an attack that does (\d+) ([a-z]+) damage at initiative (\d+)/

  def parse(input) do
    {groups, _} =
      input
      |> reduce({[], nil}, fn
        "Immune System:", {groups, _} -> {groups, :is}
        "Infection:", {groups, _} -> {groups, :inf}
        line, {groups, type} -> {[parse_line(line, type) | groups], type}
      end)
    groups
    |> reverse
    |> with_index
    |> map(fn {gr, id} -> {id, gr} end)
    |> into(%{})
  end

  defp parse_line(line, type) do
    [[_, nr, hp, weak_imun, ad, at, prio]] = Regex.scan(@regex, line)
    weak_imun = parse_weak_imun(weak_imun)
    %Group{
      nr: nr |> to_i,
      hp: hp |> to_i,
      ad: ad |> to_i,
      at: at,
      prio: prio |> to_i,
      weak: Map.get(weak_imun, :weak, []),
      imun: Map.get(weak_imun, :imun, []),
      type: type
    }
  end

  def parse_weak_imun(""), do: %{}
  def parse_weak_imun(weak_imun) do
    weak_imun
    |> Str.trim(" (")
    |> Str.trim(")")
    |> Str.split("; ")
    |> map(fn
      "weak to " <> types -> {:weak, types |> Str.split(", ")}
      "immune to " <> types -> {:imun, types |> Str.split(", ")}
    end)
    |> into(%{})
  end
end

defmodule Simulator do

  def combat(groups) do
    loop(groups, fn groups ->
      #IO.inspect(groups)
      if !any?(groups, fn {_, gr} -> gr.type === :inf end) || !any?(groups, fn {_, gr} -> gr.type === :is end) do
        throw(groups)
      end
      new_groups = fight(groups)
      if new_groups === groups do
        throw([])
      end
      new_groups
    end)
  end

  def fight(groups) do
    groups
    |> sort_by(fn {_id, gr} -> {gr.nr * gr.ad, gr.prio} end, &Kernel.>/2)
    |> reduce({groups, []}, fn group, {def_groups, attacks} ->
      {def_groups, attack} = select_target(def_groups, group)
      {def_groups, [attack | attacks]}
    end)
    |> elem(1)
    |> sort_by(fn {id, _} -> groups[id].prio end, &Kernel.>/2)
    |> reduce(groups, &attack_target(&2, &1))
  end

  defp select_target(groups, {id, %Group{at: at, type: type}}) do
    target_group_ids =
      groups
      |> filter(fn {_id, gr} -> gr.type !== type end)
      |> sort_by(fn {_id, gr} -> {map_weak_imun(gr, at), gr.nr * gr.ad, gr.prio} end, &Kernel.>/2)
      |> map(fn {id, _} -> id end)
    if len(target_group_ids) > 0 do
      target_id = hd(target_group_ids)
      {Map.delete(groups, target_id), {id, target_id}}
    else
      {groups, {id, nil}}
    end
  end

  defp map_weak_imun(gr, at) do
    cond do
      member?(gr.imun, at) -> -1
      member?(gr.weak, at) -> 1
      true -> 0
    end
  end

  defp attack_target(groups, {_id, nil}), do: groups
  defp attack_target(groups, {id, target_id}) do
    at_group = groups[id]
    if at_group !== nil do
      def_group = groups[target_id]
      damage = calculate_damage(at_group, def_group)
      loss = (damage / def_group.hp) |> trunc
      remaining = def_group.nr - loss
      #IO.puts("#{Str.upcase(Atom.to_string(at_group.type))} with id #{id} deals #{damage} damage to group with id #{target_id}, killing #{loss} units, remaining #{remaining}")
      if remaining <= 0 do
        Map.delete(groups, target_id)
      else
        Map.put(groups, target_id, %{def_group | nr: remaining})
      end
    else
      groups
    end
  end

  defp calculate_damage(attacking_group, defending_group) do
    effective_power = attacking_group.ad * attacking_group.nr
    cond do
      member?(defending_group.imun, attacking_group.at) -> 0
      member?(defending_group.weak, attacking_group.at) -> effective_power * 2
      true -> effective_power
    end
  end
end

defmodule View do

  def display(groups) do
    IO.puts("")
    {is, inf} = split_with(groups, fn {_id, gr} -> gr.type === :is end)
    IO.puts("Immune system:")
    each(is, fn {id, %Group{nr: nr}} -> IO.puts("#{id} -> #{nr}") end)
    IO.puts("Infection:")
    each(inf, fn {id, %Group{nr: nr}} -> IO.puts("#{id} -> #{nr}") end)
    IO.puts("")
  end

end

groups = Parser.parse(input)

# first

groups
|> Simulator.combat
|> map(fn {_, gr} -> gr.nr end)
|> sum
|> p

#second

defmodule Booster do

  def add_boost(groups, boost) do
    map(groups, fn {id, gr} ->
      if gr.type === :is do
        {id, %{gr | ad: gr.ad + boost}}
      else
        {id, gr}
      end
    end)
    |> into(%{})
  end

end

loop(16, fn boost ->
  IO.inspect(boost)
  result =
    groups
    |> Booster.add_boost(boost)
    |> Simulator.combat
    |> filter(fn {_, gr} -> gr.type === :is end)
    |> map(fn {_, gr} -> gr.nr end)
    |> sum()
  if result !== 0 do
    throw(result)
  end
  boost + 1
end)
|> p
