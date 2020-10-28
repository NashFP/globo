defmodule Globo do
  def demo do
    100..110
    |> Enum.each(fn x -> put("#{x}", x) end)
  end

  def get(key) do
    Globo.Mailroom.deliver_actor_call(key, :get, [])
  end

  def put(key, value) do
    Globo.Mailroom.deliver_actor_call(key, :put, [value])
  end

  def speak(key) do
    Globo.Mailroom.deliver_actor_call(key, :speak, [])
    |> IO.inspect(label: "Speaking")
  end
end
