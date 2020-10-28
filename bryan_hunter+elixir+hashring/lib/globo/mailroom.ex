defmodule Globo.Mailroom do
  use GenServer

  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def deliver_actor_call(key, function, args) do
    GenServer.call(__MODULE__, {:deliver_actor_call, key, function, args})
  end

  # GenServer Callbacks
  def init(_) do
    state = %{ring: rebuild_ring()}
    :net_kernel.monitor_nodes(true)
    {:ok, state}
  end

  def handle_call({:deliver_actor_call, key, function, args}, _from, state) do
    reply = state.ring |> perform_delivery(key, function, args)
    {:reply, reply, state}
  end

  def handle_info({node_up_or_down, _node}, state) when node_up_or_down in [:nodeup, :nodedown] do
    new_ring = rebuild_ring()

    new_ring |> move_misplaced_actors()

    {:noreply, %{state | ring: new_ring}}
  end

  defp rebuild_ring() do
    nodes =
      [Node.self()]
      |> Enum.concat(Node.list())
      |> Enum.sort()

    HashRing.new() |> HashRing.add_nodes(nodes)
  end

  defp perform_delivery(ring, key, function, args) do
    self = Node.self()

    ring
    |> HashRing.key_to_node(key)
    |> case do
      ^self ->
        find_or_create(key)
        apply(Globo.Actor, function, Enum.concat([key], args))

      remote_node ->
        :rpc.call(remote_node, Globo.Mailroom, :deliver_actor_call, [
          key,
          function,
          args
        ])
    end
  end

  defp find_or_create(key) do
    Registry.lookup(:actor_registry, key)
    |> case do
      [{_pid, ^key}] ->
        key

      _ ->
        Globo.ActorSupervisor.start_child(key)
        key
    end
  end

  defp move_misplaced_actors(ring) do
    misplacted_actor_keys =
      Globo.ActorSupervisor
      |> Supervisor.which_children()
      |> Enum.map(fn
        {_, pid, _, _} -> Registry.keys(:actor_registry, pid) |> List.first()
      end)
      |> Enum.reject(fn key -> HashRing.key_to_node(ring, key) == Node.self() end)

    misplacted_actor_keys
    |> Enum.each(fn
      key ->
        value = Globo.Actor.get(key)

        perform_delivery(ring, key, :put, [value])
        Globo.ActorSupervisor.terminate_child(key)
        key |> IO.inspect(label: "Moved misplaced actor")
    end)
  end
end
