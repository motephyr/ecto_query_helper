
defmodule EctoQueryHelper do
  defmacro extends(repo, adapter) do
    module = Macro.expand(Ecto.Repo.Queryable, __CALLER__)
    repo = Macro.expand(repo, __CALLER__)
    adapter = Macro.expand(adapter, __CALLER__)

    functions = module.__info__(:functions)
    # module_name = module.__info__(:module)

    signatures = Enum.map functions, fn { name, arity } ->
      args = if arity == 0 do
               []
             else
               Enum.map 1 .. arity, fn(i) ->
                { String.to_atom(<< ?x, ?A + i - 1 >>), [], nil }
              end
             end
      { name, [], args }
    end

    for i <- signatures do
      generate_dynamic(i, module, repo, adapter) 
    end
  end


  def generate_dynamic(i, module, repo, adapter) do
    method_name = i |> elem(0)
    args = i |> elem(2)
    
    last_args = args |> List.delete_at(length(args) -1) |> List.delete_at(0) |> List.delete_at(0) |> List.delete_at(0) 
    quote do
      def unquote(method_name)(unquote_splicing(last_args)) do       
        :erlang.apply unquote(module), unquote(method_name), [unquote(repo), unquote(adapter), __ENV__.module, unquote_splicing(last_args), []]
      end
    end

  end
end