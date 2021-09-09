defmodule ExRender do
  @moduledoc """
  Documentation for `ExRender`.
  """

  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      @after_compile __MODULE__

      @templates_root Keyword.get(opts, :templates_root, "priv/render/templates")
      @output_root Keyword.get(opts, :output_root, "lib/render_template")

      def __after_compile__(_, _) do
        _ = File.rm_rf(@output_root) |> IO.inspect()

        for p <- Path.wildcard("#{@templates_root}/**/*.*") do
          p2 = Path.rootname(p) <> ".ex"

          output_file_name =
            String.replace_prefix(
              p2,
              @templates_root,
              @output_root
            )

          do_build(p, output_file_name)
          IO.puts("#{p} => #{output_file_name}")
        end
      end

      defp do_build(source, target) do
        content = File.read!(source)

        mod =
          target
          |> Path.rootname()
          |> Path.split()
          |> then(fn l ->
            [_ | tail] = l
            tail
          end)
          |> Enum.map(fn ele ->
            ele
            |> String.split("_")
            |> Enum.map(&String.capitalize/1)
            |> Enum.join()
          end)
          |> Enum.join(".")
          |> IO.inspect(label: "build Mod Name")

        with :ok <- File.mkdir_p(Path.dirname(target)) do
          File.write(target, "defmodule #{mod} do
            def read, do: \"#{content}\"
          end
          ")
        end
      end

      def render(path, bindings \\ [], opts \\ []) do
        mod_name =
          @output_root
          |> Path.join(path)
          |> Path.split()
          |> then(fn [_ | t] = x -> t end)
          |> Enum.map(fn ele ->
            ele
            |> String.split("_")
            |> Enum.map(&String.capitalize/1)
            |> Enum.join()
          end)
          |> Enum.join(".")
          |> IO.inspect(label: "render mod name")

        content = apply(:"Elixir.#{mod_name}", :read, [])
        EEx.eval_string(content, bindings, opts)
      end
    end
  end
end
