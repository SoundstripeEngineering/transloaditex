defmodule Transloaditex.File do
  def add_file(files, file_path, field_name) when is_list(files) do
    field_name = get_field_name(files, field_name)
    file_map = Map.new([{field_name, file_path}])

    [file_map | files]
  end

  def add_file(files, file_path) when is_list(files), do: add_file(files, file_path, nil)

  def add_file(file_path, field_name) when is_binary(file_path),
    do: add_file([], file_path, field_name)

  def add_file(file_path), do: add_file([], file_path, nil)

  def remove_file(files, value) do
    Enum.reject(files, fn file ->
      Map.has_key?(file, value) or Map.values(file) |> Enum.member?(value)
    end)
  end

  def get_files(files), do: Enum.reduce(files, %{}, &Map.merge/2)

  def get_field_name(files, name) when is_nil(name), do: get_field_name(files, "file")

  def get_field_name(files, name) do
    if has_field_name?(files, name) do
      get_next_name(files, name)
    else
      name
    end
  end

  defp get_next_name(files, base_name), do: get_next_name(files, base_name, 1)

  defp get_next_name(files, base_name, counter) do
    name = "#{base_name}_#{counter}"

    if has_field_name?(files, name) do
      get_next_name(files, base_name, counter + 1)
    else
      name
    end
  end

  defp has_field_name?(files, field_name) do
    Enum.any?(files, fn file -> Map.has_key?(file, field_name) end)
  end
end
