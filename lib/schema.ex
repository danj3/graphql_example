defmodule GExample.Schema do
  use Absinthe.Schema
  import_types GExample.Types

  query do
    field :ping, :string do
      resolve fn _p, _a, _i -> {:ok, "pong" } end
    end

    field :s1, :complex_status do
      arg :in1, :string
      resolve fn  parent, args, _  ->
	      IO.inspect( { :top, parent, args, self() } )
	      { :ok, %{ a: args[:in1] } }
      end
    end

    field :simple_list, list_of( :simple_object ) do
      resolve fn _parent, _args, _c ->
	      { :ok, %{ x: 55, y: 77, z: 99 } }
      end
    end
  end

end
