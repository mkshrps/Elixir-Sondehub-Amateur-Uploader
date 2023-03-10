defmodule Sondehub.Listener.Server do
  use GenServer

  # start the genserver to fire up every n seconds
  def init(listener) do

    new_state =
      %{:last_response => %{:status_code => 0, :status_msg => ""},
        :listener_data => listener}

    :timer.send_after(5_000,:update_listener)
    {:ok,new_state}
    # set timer

  end
  def handle_info(:update_listener,state) do
    response = Sondehub.Listener.Impl.upload_listener(state.listener_data)
    # update with response from attempted upload
    new_state = handle_response(response,state)

    :timer.send_after(10_000,:update_listener)
    {:noreply, new_state}
  end

  #  position = [lat,lon,alt]
  def handle_call({:set_position, position},_from,state)  do
    # position must be a complete keywordlist
    new_state = Keyword.replace(state.listener_data, :uploader_position, position)
    |> update_listener_state(state)
    {:reply,:ok,new_state}
  end

  def handle_call({:set_callsign, callsign},_from,state)  do
    # position must be a complete keywordlist
    new_state = Keyword.replace(state.listener_data, :uploader_callsign, callsign)
    |> update_listener_state(state)
    {:reply,:ok,new_state}
  end

  def handle_call({:set_mobile, mobile},_from,state)  do
    # position must be a complete keywordlist
    new_state = Keyword.replace(state.listener_data, :mobile, mobile)
    |> update_listener_state(state)
    {:reply,:ok,new_state}
  end

  # put the listener list back into state map
  def update_listener_state(listener,state) do
    put_in(state.listener_data, listener)
  end

  def handle_response({:ok, response},state) do
    new_state = put_in(state.last_response.status_code, response.status_code)
    new_state = put_in(new_state.last_response.status_msg, response.body )
    new_state
  end

  def handle_response({:error, response},state) do
    new_state = put_in(state.last_response.status_code, 0)
    new_state = put_in(new_state.last_response.status_msg, response)
    new_state
  end

  def handle_response(_,state) do
    new_state = put_in(state.last_response.status_code, 0)
    new_state = put_in(new_state.last_response.status_msg, "unknown")
    new_state
  end


end
