defmodule Transloaditex.FileTest do
  use ExUnit.Case
  alias Transloaditex.File

  @filename "file_path.jpg"
  @custom_field "custom"

  @multiple_files [
    %{"file" => "file1.jpg"},
    %{"file_1" => "file2.jpg"}
  ]

  @single_file [
    %{"custom" => "existing.jpg"}
  ]

  test "should add a file with default 'file' field name" do
    files = File.add_file(@filename)
    assert files == [%{"file" => @filename}]
  end

  test "should add a file with a custom field name" do
    files = File.add_file(@filename, @custom_field)
    assert files == [%{@custom_field => @filename}]
  end

  test "should add a file to an existing list with default field name" do
    files = File.add_file(@multiple_files, @filename)
    assert files == [%{"file_2" => @filename} | @multiple_files]
  end

  test "should add a file to an existing list with custom field name" do
    files = File.add_file(@single_file, @filename, @custom_field)
    assert files == [%{"custom_1" => @filename} | @single_file]
  end

  test "should remove a file by its field name from an existing list" do
    new_files = File.remove_file(@multiple_files, "file")
    assert new_files == [%{"file_1" => "file2.jpg"}]
  end

  test "should remove a file byt its file_path from an existing list" do
    new_files = File.remove_file(@multiple_files, "file2.jpg")
    assert new_files == [%{"file" => "file1.jpg"}]
  end

  test "should merge multiple file maps into a single map" do
    merged_files = File.get_files(@multiple_files)
    assert merged_files == %{"file" => "file1.jpg", "file_1" => "file2.jpg"}
  end

  test "should return next unique field name in an existing list" do
    assert File.get_field_name(@multiple_files, "file") == "file_2"
  end
end
