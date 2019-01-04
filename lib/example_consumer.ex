defmodule ExampleConsumer do
  # function to accept Kafka messaged MUST be named "handle_message"
  # MUST accept arugments structured as shown here
  # MUST return :ok
  # Can do anything else within the function with the incoming message

  def handle_message(%{key: key, value: value} = message) do # necessary
    IO.inspect message # optional
    IO.puts "#{key}: #{value}" # optional
    :ok # necessary
  end
end
