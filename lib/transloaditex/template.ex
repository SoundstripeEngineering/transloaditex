defmodule Transloaditex.Template do
  alias Transloaditex.Request
  alias Transloaditex.Step

  @doc """
  ...
  """
  def create_template(name, steps) when is_list(steps) do
    template = Step.get_steps(steps)
    Request.post("/templates", %{name: name, template: template})
  end

  def create_template(_),
    do:
      {:error,
       "Missing or invalid arguments. Provide a name and either list of steps or JSON Encoded params"}

  def create_template(),
    do:
      {:error,
       "Missing or invalid arguments. Provide a name and either list of steps or JSON Encoded params"}

  @doc """
  Update the template specified by the 'template_id'.

  ## Args:

    * `template_id` (str)
    * `data` (map) - key, value pair of fields and their new values.

  ## Returns:

    An instance of `Transloaditex.Response`.
  """
  def update_template(template_id, data) when is_list(data) do
    template = %{steps: Step.get_steps(data)}
    Request.put("/templates/#{template_id}", %{template: template})
  end

  @doc """
  Get the template specified by template id or template url

  ## Args:

    * `template` (str) - One of template id or template url

  ## Returns:

    An instance of `Transloaditex.Response`
  """
  def get_template(template) do
    url = Request.to_url("templates", template)

    Request.get(url)
  end

  def get_template(), do: {:error, "Missing or invalid arguments. Provide an template id or url"}

  @doc """
  Get the list of templates

  ## Args:

    * `options` (Optional[map]):
        params to send along with the request. Please see
        https://transloadit.com/docs/api-docs/#45-retrieve-template-list for available options.

  ## Returns:

    An instance of `Transloaditex.Response`.
  """
  def list_templates(params), do: Request.get("/templates", params)

  def list_templates(), do: list_templates(%{})

  @doc """
  Delete the template specified by the 'template_id'.

  ## Args:

    * `template_id` (str)

  ## Returns:

    An instance of `Transloaditex.Response`.
  """
  def delete_template(template) do
    url = Request.to_url("templates", template)
    Request.delete(url)
  end

  def delete_template(),
    do: {:error, "Missing or invalid argument. Provide a valid template url or template id"}

  def get_template_id(name) when is_binary(name) do
    case list_templates() do
      %Transloaditex.Response{status_code: 200, data: %{"items" => items}} ->
        case Enum.find(items, fn item -> item["name"] == name end) do
          nil ->
            {:error, "Template not found"}

          item ->
            id = item["id"]
            {:ok, id}
        end

      %Transloaditex.Response{status_code: status_code} when status_code != 200 ->
        {:error, "Received non-200 status: #{status_code}"}

      _ ->
        {:error, "Unexpected response format"}
    end
  end

  def get_template_id(_),
    do: {:error, "Missing or invalid argument. Provide a valid template name"}

  def get_template_id(),
    do: {:error, "Missing or invalid argument. Provide a valid template name"}
end
