defmodule Sondehub.Listener.Server do
  use GenServer
  require Logger
  @listener_update_interval 10_000

  # start the genserver to fire up every n seconds
  def init(listener) do

    new_state =
      %{:last_response => %{:status_code => 0, :status_msg => ""},
        :listener_data => listener}
    XGPS.Ports.start_port("ttyAMA0")
    :timer.send_after(5_000,:update_listener)
    {:ok,new_state}
    # set timer

  end

  # timed update of listener position
  def handle_info(:update_listener,state) do
    Logger.info("updating Listener")
    {:ok,gps_map} = XGPS.Ports.get_one_position()
    Logger.info("gps map - #{gps_map}")
    state = get_new_pos(gps_map,state)
    response = Sondehub.Listener.Impl.upload_listener(state.listener_data)
    # update with response from attempted upload
    new_state = handle_response(response,state)

    :timer.send_after(@listener_update_interval,:update_listener)
    {:noreply,new_state}
  end


     #  position = [lat,lon,alt]
  def handle_cast({:set_position_from_list, position},state)  do
    # position must be a complete keywordlist
    new_state = if position_valid?(position) do

      Keyword.replace(state.listener_data, :uploader_position, position)
      |> update_listener_state(state)
      |> set_new_position()
    else
      state
    end
    {:noreply,new_state}
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

  def handle_call(:get_position,_from,state) do
    {:reply,state.listener.uploader_position,state}
  end

  def test_event(event) do
    IO.inspect(event.altitude)
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

  def get_new_pos(gps_map,state) when gps_map.has_fix == true do
    Logger.info("save new position")
    {altitude,_} = gps_map.altitude
    position = [gps_map.latitude, gps_map.longitude,altitude]
    Keyword.replace(state.listener_data, :uploader_position, position)
    |> update_listener_state(state)
  end
  # do nothing
  def get_new_pos(_gps_map,state) do
    Logger.info("no new position available")
    state
  end

  def position_valid?([lat, lon, _alt] = _position) do
    if (lon >= 0.0 && lat >=0.0) do
      true
    else false
    end
  end

  # returns updated state
  def set_new_position(state) do
    Sondehub.Listener.Impl.upload_listener(state.listener_data)
    |> handle_response(state) # updat state with response
  end
end
