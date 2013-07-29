# FsmDsl

A DSL wrapper for Elixir's GenFSM.Behaviour. For example:

~~~ elixir
defmodule Listen.NewFSM do

  use Daves.Fsm,  register: {:local, :listen_fsm},
                  initial_state: :start,
                  init_params: []

  @timeout 3*1000

  defrecord CallInfo, from: "", to: "", suspicious_segments: 0

  ####################
  #
  # Events → our external API

  events do
    call_initiated(from, to)
    suspicious_phrase_heard
    hang_up
  end

  ####################
  #
  # States → transitions we implement

  in_state(:start) do
    { :call_initiated, from, to } ->
      IO.puts "Initiating a call from #{from} to #{to}"
      next_state(:listening, CallInfo.new(from: from, to: to))
  end

  in_state(:listening) do
    { :hang_up } ->
      debug("Hangup", context)
      next_state(:start, nil)

    { :suspicious_phrase_heard } ->
      debug("Heard something suspicious", context)
      next_state(:transcribing, context.update_suspicious_segments(&1+1), @timeout)
  end

  in_state(:transcribing) do
    { :hang_up } ->
      debug("Report on call", context)
      next_state(:start, CallData.new)

    { :timeout } ->
      next_state(:listening, context)
  end

  # Helpers

  defp debug(msg, CallInfo[from: from, to: to, suspicious_segments: suspicious_segments]) do
    IO.puts("Call from #{from} to #{to}: #{msg}")
    if suspicious_segments > 0 do
      IO.puts("    (suspicious_segments: #{suspicious_segments})")
    end
  end
end
~~~

There are three sections in this code

1. The `use` stanza.
2. The `event list`
3. The `state definitions`

## `context` vs. `state`

In an Erlang server, state is passed between callbacks. However, it gets confusing talking 
about this server state when we also have the concept of state machine states. So, in this
module, we use the convention that the server state is called the `context`.


## The `use` stanza

As well as including the FsmDsl behaviour in your module, the `use` call lets you set various options:

| Option        | Default         | Meaning             |
| ------------- | --------------- | --------------------|
| register      | {:local, :fsm } | The first argument to `start_link`, used to register a name for this module |
| initial_state | :state          | The name of the initial state of the FSM   |
| context       | []              | The initial context |
| ------------- | --------------- | --------------------|


### The Event List

In GenFSM, events are triggered by calls to public functions. Each function then calls `send_event`
to cause the appropriate callback to be invoked.

This code is pretty boilerplate, so we abstract it into an `events` stanza:

~~~ elixir
events do
  call_initiated(from, to)
 suspicious_phrase_heard
  hang_up
end
~~~

This block simply creates the following functions:

~~~ elixir
def call_initiated(from, to) do
  :gen_fsm.send_event(«servername», :call_initiated, from, to)
end
def suspicious_phrase_heard do
  :gen_fsm.send_event(«servername», :suspicious_phrase_heard)
end
def hang_up do
  :gen_fsm.send_event(«servername», hang_up)
end
~~~

You're free to write these functions by hand, too.

## The States

We represent each state using `in_state(«name»)`. Within the block, separate clauses
match each incoming event (with optional parameters). The code corresponding with the match
will end with a call to `next_state`, which takes the new state name, the new context, and an optional timeout (in mS).

~~~ elixir
in_state(:listening) do
  { :hang_up } ->
    debug("Hangup", context)
    next_state(:start, nil)

  { :suspicious_phrase_heard } ->
    debug("Heard something suspicious", context)
    next_state(:transcribing, context.update_suspicious_segments(&1+1), @timeout)
end
~~~

So, if we're in state `listening` and we get a `hang_up` event,  we call `debug` to print a message, 
and then transition to the state state, with no context. If instead we get a `suspicious_phrase_heard` 
event, we transition to the `transcribing` state. We pass an updated context where we increment the
number of suspicious segments, and we set a timeout.

If a timeout fires, it generates a `timeout` event in the next state (there's an example in the `transcribing` 
state of the sample app)

## Author

Dave Thomas, The Pragmatic Programmers. dave@pragprog.com. @/+pragdave

## License

See LICENSE.
