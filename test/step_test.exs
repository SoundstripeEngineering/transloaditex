defmodule Transloaditex.StepTest do
  use ExUnit.Case
  alias Transloaditex.Step

  @initial_steps [%{"resize" => %{robot: "/image/resize"}}]
  @name "optimize"
  @robot "/test/optimize"
  @opts %{quality: 90}

  describe "add_step/3, add_step/4" do
    test "adds a step with options to an existing list of steps" do
      steps = Step.add_step(@initial_steps, @name, @robot, @opts)
      assert steps == [%{@name => %{robot: @robot, quality: 90}} | @initial_steps]
    end

    test "adds a step without options to an existing list of steps" do
      steps = Step.add_step(@initial_steps, @name, @robot)
      assert steps == [%{@name => %{robot: @robot}} | @initial_steps]
    end

    test "creates a new step with options when no initial steps are provided" do
      steps = Step.add_step(@name, @robot, @opts)
      assert steps == [%{@name => %{robot: @robot, quality: 90}}]
    end

    test "creates a new step without options when no initial steps are provided" do
      steps = Step.add_step(@name, @robot)
      assert steps == [%{@name => %{robot: @robot}}]
    end
  end

  describe "remove_step/2" do
    test "remove a step by its name" do
      steps = [%{@name => %{robot: @robot}}, %{"resize" => %{robot: "/image/resize"}}]
      new_steps = Step.remove_step(steps, @name)
      assert new_steps == [@initial_steps |> List.first()]
    end
  end

  describe "get_steps/1" do
    test "merges all steps into a single map" do
      steps = [
        %{@name => %{robot: @robot, quality: 90}},
        %{"resize" => %{robot: "/image/resize"}}
      ]

      merged_steps = Step.get_steps(steps)

      assert merged_steps == %{
               @name => %{robot: @robot, quality: 90},
               "resize" => %{robot: "/image/resize"}
             }
    end
  end
end
