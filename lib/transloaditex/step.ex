defmodule Transloaditex.Step do
  def add_step(steps, name, robot, opts) when is_list(steps) do
    step_map = %{
      name => Map.merge(%{robot: robot}, Map.new(opts))
    }

    [step_map | steps]
  end

  def add_step(steps, name, robot) when is_list(steps), do: add_step(steps, name, robot, %{})

  def add_step(name, robot, opts) when is_binary(name), do: add_step([], name, robot, opts)

  def add_step(name, robot) when is_binary(name), do: add_step([], name, robot, %{})

  def remove_step(steps, name), do: Enum.reject(steps, &Map.has_key?(&1, name))

  def get_steps(steps), do: Enum.reduce(steps, %{}, &Map.merge/2)
end
