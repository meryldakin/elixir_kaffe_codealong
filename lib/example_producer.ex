defmodule ExampleProducer do
  def send_my_message({key, value}, topic) do
    Kaffe.Producer.produce_sync(topic, [{key, value}])
  end

  def send_my_message(key, value) do
    Kaffe.Producer.produce_sync(key, value)
  end

  def send_my_message(value) do
    Kaffe.Producer.produce_sync("sample_key", value)
  end
end
