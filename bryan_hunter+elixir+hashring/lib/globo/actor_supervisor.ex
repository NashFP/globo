defmodule Globo.ActorSupervisor do
  use DynamicSupervisor

  def start_link() do
    DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_child(key) do
    spec = %{id: Globo.Actor, start: {Globo.Actor, :start_link, [key]}}
    DynamicSupervisor.start_child(__MODULE__, spec)
  end

  def terminate_child(key) do
    Registry.lookup(:actor_registry, key)
    |> case do
      [{pid, _}] ->
        DynamicSupervisor.terminate_child(__MODULE__, pid)
        :terminated

      _ ->
        :not_found
    end
  end
end
