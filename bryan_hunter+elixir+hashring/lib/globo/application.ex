defmodule Globo.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      Supervisor.Spec.supervisor(Registry, [:unique, :actor_registry]),
      Supervisor.Spec.supervisor(Globo.ActorSupervisor, []),
      Supervisor.Spec.worker(Globo.Mailroom, [])
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
