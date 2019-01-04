# Connecting Elixir to Kafka with Kaffe: A codealong
_The most basic example that exists_

If we want to use the popular messaging system Kafka with our Elixir projects, we have a few wrappers we can choose from. One of them, [Kaffe](https://github.com/spreedly/kaffe), proved difficult to troubleshoot. Just try googling "Elixir Kaffe" yourself.

In this codealong we'll build the barest of simple Elixir applications and use Kaffe to connect it to a locally running Kafka server. Later we'll cover a couple of variations to connect a dockerized Kafka server or an umbrella elixir app.

This post assumes basic knowledge of Elixir and no knowledge of Kafka or Kaffe. Here is the repo with the full project: ElixirExampleKaffe Codealong

## What is Kafka, briefly?
Kafka is a messaging system. It does essentially three things:
1. Receives messages from applications
2. Keeps those messages in the order they were receieved in
3. Allows other applications to read those messages in order

Learn a lot more here: [Kafka in a Nutshell](https://sookocheff.com/post/kafka/kafka-in-a-nutshell/)

## Basic Kafka terminology in simple terms
- **consumer:** what is receiving messages from Kafka
- **producer:** what is sending messages to Kafka
- **topic:** a way to organize messages and allow consumers to only subscribe to the ones they want to receive
- **partition:** allows a topic to be split among multiple machines and retain the same data so that more than one consumer can read from a single topic at a time
- **leader/replica:** these are types of partitions. There is one leader and multiple replicas. The leader makes sure the replicas have the same and newest data. If the leader fails, a replica will take over as leader.
- **offset:** the unique identifier of a message that keeps its order within Kafka

## Codealong: basic Elixir app & Kafka running locally

### Set up Kafka Server
Follow the first two steps of the [quickstart instructions](http://kafka.apache.org/documentation/#quickstart) from Apache Kafka:
1. [Download the code](https://www.apache.org/dyn/closer.cgi?path=/kafka/2.1.0/kafka_2.11-2.1.0.tgz)
2. Start the servers
Zookeeper
`bin/zookeeper-server-start.sh config/zookeeper.properties`
Kafka
`bin/kafka-server-start.sh config/server.properties`

### Set up Elixir App

**1. Start new project**
`mix new elixir_example_kaffe`

**2. Configure kaffe**
**2.a:** In `mix.exs` add `:kaffe` to the list of extra applications:
```elixir
def application do
  [
    extra_applications: [:logger, :kaffe]
  ]
end
```

**2.b:** Add kaffe to list of dependencies:
```elixir
defp deps do
  [
    {:kaffe, "~> 1.9"}
  ]
end  
```

**2.c:** Run `mix deps.get` in the terminal to lock new dependencies.

**3. Configure producer**
in `config/config.exs` add:
```elixir
config :kaffe,
  producer: [
    endpoints: [localhost: 9092],
    # endpoints references [hostname: port]. Kafka is configured to run on port 9092.
    # In this example, the hostname is localhost because we've started the Kafka server
    # straight from our machine. However, if the server is dockerized, the hostname will
    # be called whatever is specified by that container (usually "kafka")
    topics: ["our_topic", "another_topic"], # add a list of topics you plan to produce messages to
  ]
```

**4. Configure consumer**
**4.a:** add `/lib/application.ex` with the following code:
```elixir
defmodule ElixirExampleKaffe.Application do
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
```
**4.b:** back in `mix.exs`, add a new item to the application function:
```elixir
def application do
  [
    extra_applications: [:logger, :kaffe],
    mod: {ElixirExampleKaffe.Application, []}
    # now that we're using the Application module, this is where we'll tell it to start.
    # We use the keyword `mod` with applications that start a supervision tree,
    # which we configured when adding our Kaffe.Consumer to Application above.
  ]
end
```
**4.c:** add a consumer module to accept messages from Kafka as `/lib/example_consumer.ex` with the following code:
```elixir
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
```
**4.d:** configure the consumer module in `/config/config.exs`
```elixir
config :kaffe,
  consumer: [
    endpoints: [localhost: 9092],               
    topics: ["our_topic", "another_topic"],     # the topic(s) that will be consumed
    consumer_group: "example-consumer-group",   # the consumer group for tracking offsets in Kafka
    message_handler: ExampleConsumer,           # the module that will process messages
  ]
```

**5. Add a producer module (optional, can also call Kaffe from the console)**
add `/lib/example_producer.ex` with the following code:
```elixir
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
```

**6. Send and receive messages in the console!**
Start an interactive elixir shell with `iex -S mix` and call the following:
```sh
iex> ExampleProducer.send_my_message({"Metamorphosis", "Franz Kafka"}, "another_topic")
...>[debug] event#produce_list topic=another_topic
...>[debug] event#produce_list_to_topic topic=another_topic partition=0
...>:ok
iex> %{
...> attributes: 0,
...> crc: 2125760860, # will vary
...> key: "Metamorphosis",
...> magic_byte: 1,
...> offset: 1, # will vary
...> partition: 0,
...> topic: "another_topic",
...> ts: 1546634470702, # will vary
...> ts_type: :create,
...> value: "Franz Kafka"
...> }
...> Metamorphosis: Franz Kafka
```

## Variations: Docker & Umbrella Apps
- If you're running Kafka from a docker container (most common in real applications), you will use that hostname in the config file rather than `localhost`
- In an umbrella app you'll configure Kaffe in the child application running it. If you have apps separated by environment, you can start the consumer by structuring it as a child like this:
```elixir
    children = case args do
      [env: :prod] -> [worker(Kaffe.Consumer, [])]
      [env: :test] -> []
      [env: :dev]  -> [{ElixirExampleKaffe.OtherApp, []}, worker(Kaffe.Consumer, [])] # note that it is not a tuple
      [_] -> []
    end
```

## Troubleshooting Errors
- **No leader error**
```
** (MatchError) no match of right hand side value: {:error, :LeaderNotAvailable}
```
Solution: Try again. It just needed a minute to warm up.

- **Invalid Topic error**
```
** (MatchError) no match of right hand side value: {:error, :InvalidTopicException}
```
Solution: Your topic shouldn't have spaces in it, does it?

## The end
This should have given you the basic setup for you to start exploring more of this on your own, but there's lots more you can do with Kaffe so check out sending multiple messages, consumer groups, etc. If you come up with any more troubleshooting errors you've solved, I'd love to continue adding them to what we've started here.

## Resources
- https://github.com/spreedly/kaffe
- https://hexdocs.pm/kaffe/Kaffe.html#content
- http://kafka.apache.org/documentation/#quickstart
- https://sookocheff.com/post/kafka/kafka-in-a-nutshell/
- https://hexdocs.pm/elixir/Application.html
