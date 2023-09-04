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

  describe "add_file/1" do
    # This test checks if the function correctly defaults to using "file" as the field name.
    test "returns file list with default field name when no field name supplied" do
      files = File.add_file(@filename)
      assert files == [%{"file" => @filename}]
    end
  end

  describe "add_file/2" do
    # This test checks if the function correctly assigns the provided field name
    test "returns file list with provided field name" do
      files = File.add_file(@filename, @custom_field)
      assert files == [%{@custom_field => @filename}]
    end

    test "returns file list with default incremented field name when no field name supplied and default already exists" do
      # This test checks if the function correctly assigns an incremented version
      # of the default field name when the name already exists.
      # In this case, `file` and `file_1` already exists, so it should return `file_2`
      files = File.add_file(@multiple_files, @filename)
      assert files == [%{"file_2" => @filename} | @multiple_files]
    end
  end

  describe "add_file/3" do
    # This test confirms the function correctly assigns an incremented version
    # of the supplied field name.
    test "returns file list with provided field name incremented because it already exists" do
      files = File.add_file(@single_file, @filename, @custom_field)
      assert files == [%{"custom_1" => @filename} | @single_file]
    end
  end

  describe "remove_file/2" do
    test "removes a file entry by field name" do
      new_files = File.remove_file(@multiple_files, "file")
      assert new_files == [%{"file_1" => "file2.jpg"}]
    end

    test "removes a file entry by file name" do
      new_files = File.remove_file(@multiple_files, "file2.jpg")
      assert new_files == [%{"file" => "file1.jpg"}]
    end
  end

  describe "get_files/1" do
    test "merges all files into a single map" do
      merged_files = File.get_files(@multiple_files)
      assert merged_files == %{"file" => "file1.jpg", "file_1" => "file2.jpg"}
    end
  end

  describe "get_field_name/3" do
    test "returns unique field name" do
      assert File.get_field_name(@single_file, "file") == "file"
    end

    test "returns a unique incremented field name" do
      assert File.get_field_name(@multiple_files, "file") == "file_2"
    end
  end
end
