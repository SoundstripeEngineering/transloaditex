defmodule Examples.ImageResize do
  alias Transloaditex.Step
  alias Transloaditex.File
  alias Transloaditex.Assembly

  def resize do
    files = File.add_file("assets/lol_cat.jpg")
    steps = Step.add_step("resize", "/image/resize", width: 70, height: 70)

    response = Assembly.create_assembly(%{steps: steps, files: files})

    result_url = Map.get(response.data, "results") |> Map.get("resize") |> List.first |> Map.get("ssl_url")

    IO.puts("Your result: #{result_url}")
  end
end
