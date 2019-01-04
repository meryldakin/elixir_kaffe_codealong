defmodule ElixirKaffeCodealong.Application do
  use Application # read more about Elixir's Application module here: https://hexdocs.pm/elixir/Application.html

  def start(_type, args) do
    import Supervisor.Spec
    children = [
      worker(Kaffe.Consumer, []) # calls to start Kaffe's Consumer module
    ]
    opts = [strategy: :one_for_one, name: ExampleConsumer.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
