defmodule Globo.Actor do
  use GenServer

  def start_link(key) do
    GenServer.start_link(__MODULE__, key, name: via_tuple(key))
  end

  defp via_tuple(key) do
    {:via, Registry, {:actor_registry, key}}
  end

  def get(key) do
    GenServer.call(via_tuple(key), :get)
  end

  def put(key, value) do
    GenServer.call(via_tuple(key), {:put, value})
  end

  def speak(key) do
    GenServer.call(via_tuple(key), :speak)
  end

  # GenServer Callbacks

  def init(key) do
    {:ok, %{key: key, value: nil}}
  end

  def handle_call(:get, _from, state) do
    {:reply, state.value, state}
  end

  def handle_call({:put, value}, _from, state) do
    {:reply, :ok, %{state | value: value}}
  end

  def handle_call(:speak, _from, state) do
    reply =
      "Actor #{inspect(state.key)} on node #{Node.self()} has value: #{inspect(state.value)}"

    {:reply, reply, state}
  end
end
