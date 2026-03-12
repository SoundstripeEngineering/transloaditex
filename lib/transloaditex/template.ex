defmodule Transloaditex.Template do
  alias Transloaditex.Step

  defp request, do: Application.get_env(:transloaditex, :request, Transloaditex.Request)

  @doc """
  Create a new template.

  ## Args

    * `name` - Template name (5-40 chars, lowercase, dashes and latin letters only)
    * `steps` - List of step maps built with `Transloaditex.Step`

  ## Returns

    A `Transloaditex.Response` struct or `{:error, reason}`.
  """
  def create_template(name, steps) when is_binary(name) and is_list(steps) do
    template = Step.get_steps(steps)
    request().post("/templates", %{name: name, template: Jason.encode!(template)})
  end

  def create_template(_, _),
    do:
      {:error,
       "Missing or invalid arguments. Provide a name and either list of steps or JSON Encoded params"}

  @doc """
  Update the template specified by the 'template_id'.

  Accepts either a list of steps (backward compatible) or a map of parameters
  for full control over what gets updated.

  ## With a list of steps

      update_template("abc123", [%{"resize" => %{robot: "/image/resize"}}])

  ## With a map of parameters

      update_template("abc123", %{
        name: "new_name",
        steps: [%{"resize" => %{robot: "/image/resize"}}],
        require_signature_auth: 1
      })

  ## Returns

    A `Transloaditex.Response` struct or `{:error, reason}`.
  """
  def update_template(template_id, steps) when is_binary(template_id) and is_list(steps) do
    template = Step.get_steps(steps)
    request().put("/templates/#{template_id}", %{template: Jason.encode!(template)})
  end

  def update_template(template_id, params) when is_binary(template_id) and is_map(params) do
    data =
      case Map.pop(params, :steps) do
        {nil, data} -> data
        {steps, data} -> Map.put(data, :template, Jason.encode!(Step.get_steps(steps)))
      end

    request().put("/templates/#{template_id}", data)
  end

  def update_template(_, _),
    do: {:error, "Missing or invalid arguments. Provide a valid template id and steps or params"}

  @doc """
  Get the template specified by template id or template url.
  """
  def get_template(template) when is_binary(template) do
    case Transloaditex.Request.to_url("templates", template) do
      {:error, _} = error -> error
      url -> request().get(url)
    end
  end

  def get_template(_), do: {:error, "Invalid argument. Provide a template id or url"}

  @doc """
  List templates with optional filter parameters.

  See https://transloadit.com/docs/api/templates-get/ for available options.
  """
  def list_templates(params \\ %{}), do: request().get("/templates", params)

  @doc """
  Delete the template specified by template id or template url.
  """
  def delete_template(template) when is_binary(template) do
    case Transloaditex.Request.to_url("templates", template) do
      {:error, _} = error -> error
      url -> request().delete(url)
    end
  end

  def delete_template(_),
    do: {:error, "Invalid argument. Provide a valid template url or template id"}

  @doc """
  Look up a template's id by its name.

  Searches through the first page of templates. For accounts with many
  templates, consider using `list_templates/1` with the `:keywords` option.
  """
  def get_template_id(name) when is_binary(name) do
    case list_templates(%{keywords: [name]}) do
      %Transloaditex.Response{status_code: 200, data: %{"items" => items}} ->
        case Enum.find(items, fn item -> item["name"] == name end) do
          nil -> {:error, "Template not found"}
          item -> {:ok, item["id"]}
        end

      %Transloaditex.Response{status_code: status_code} when status_code != 200 ->
        {:error, "Received non-200 status: #{status_code}"}

      _ ->
        {:error, "Unexpected response format"}
    end
  end

  def get_template_id(_),
    do: {:error, "Missing or invalid argument. Provide a valid template name"}
end
