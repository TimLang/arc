defmodule Arc.Transformations.Convert do
  def apply(cmd, file, args) do
    new_path = Arc.File.generate_temporary_path(file)
    args     = if is_function(args), do: args.(file.path, new_path), else: [file.path | (String.split(args, " ") ++ [new_path])]
    program  = to_string(cmd)

    ensure_executable_exists!(program)

    file_path = hd(args)
    if is_gif?(file_path) do
      if Enum.at(args, 1) == "-thumbnail" do
        case System.cmd(program, args_list(generate_thumbnail_execute_args(args)), stderr_to_stdout: true) do
          {_, 0} ->
            {:ok, %Arc.File{file | path: new_path}}
          {error_message, _exit_code} ->
            {:error, error_message}
        end
      else
        {:ok, %Arc.File{file | path: file_path} }
      end
    else
      case System.cmd(program, args_list(args), stderr_to_stdout: true) do
        {_, 0} ->
          {:ok, %Arc.File{file | path: new_path}}
        {error_message, _exit_code} ->
          {:error, error_message}
      end
    end
  end

  defp args_list(args) when is_list(args), do: args
  defp args_list(args), do: ~w(#{args})

  defp ensure_executable_exists!(program) do
    unless System.find_executable(program) do
      raise Arc.MissingExecutableError, message: program
    end
  end

  defp is_gif? file_path do
    result = to_string("identify #{file_path} | head -n1" |> String.to_char_list |> :os.cmd)
    Regex.match?(~r/[\S]+[[:blank:]]+GIF[[:blank:]]\d+x\d+/, result)
  end

  defp generate_thumbnail_execute_args args do
    last_arg = List.last args
    Enum.drop(args, -1) ++ ["-delete", "1--1", last_arg]
  end

end
