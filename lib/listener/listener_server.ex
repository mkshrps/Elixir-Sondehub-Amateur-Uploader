defmodule Sondehub.Listener.Server do
  use GenServer
  require Logger
  alias Sondehub.Listener.ValidatePosition, as: Validator
  @listener_update_interval_mobile 25_000

  @listener_update_interval_static 60_000

  @doc """
    posn = [lat,lon,alt]
    Sondehub amatuer listener data  format
  {
    "software_name": ,
    "software_version": ,
    "uploader_callsign": ,
    "uploader_position": [
      0,
      0,
      0
    ],
    "uploader_antenna": ,
    "uploader_contact_email": ,
    "mobile": true
  }
  """

  # start the genserver to fire up every n seconds
  def init(listener) do

   XGPS.Ports.start_port("ttyAMA0")
    timer_ref = Process.send_after(self(),:update_listener,5_000)
    new_state =
      %{:last_response => %{:status_code => 0, :status_msg => ""},:timer => timer_ref,
        :listener_data => listener}
     {:ok,new_state}
    # set timer

  end

  @doc """
    get latest values from GPS
    do timed update of listener position if mobile
  """
  def handle_info(:update_listener,state) do
    #Logger.info("updating Listener")
    {:ok,gps_map} = XGPS.Ports.get_one_position()
    #Logger.info("gps map - #{inspect(gps_map)}")
    state = save_new_position(gps_map,state)
    # directly upload the position to sondehub
    #Logger.info("uploader position is #{inspect(state.listener_data[:uploader_position])}")
    response = upload_new_position(state)
    # update with response from attempted upload
    new_state = handle_response(response,state)

    update_interval = get_update_interval(state)
    timer_ref = Process.send_after(self(),:update_listener,update_interval)
    new_state = Map.put(new_state,:timer,timer_ref)

    {:noreply,new_state}
  end


     #  position = [lat,lon,alt]
  def handle_cast({:set_position_from_list, position},state)  do
    # parse input and transform to format [lat,lon,alt]
    geo_position = Validator.parse_position(position)

    new_state = if Validator.validate_gps_coordinates(geo_position) do

      Keyword.replace(state.listener_data, :uploader_position, position)
      |> update_listener_state(state)
      |> upload_new_position()
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
    if(state.timer != nil) do
      Process.cancel_timer(state.timer)
    end
    timer_ref = Process.send_after(self(),:update_listener,5_000)
    new_state =
    Keyword.replace(state.listener_data, :mobile, mobile)
    |> update_listener_state(state)
    |> Map.put(:timer,timer_ref)

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

  def save_new_position(gps_map,state) when gps_map.has_fix == true do
    Logger.info("save new position")
    {altitude,_} = gps_map.altitude
    position = [gps_map.latitude, gps_map.longitude,altitude]
    Keyword.replace(state.listener_data, :uploader_position, position)
    |> update_listener_state(state)
  end
  # do nothing
  def save_new_position(_gps_map,state) do
    Logger.info("no new position available")
    state
  end

  def position_valid?([lat, lon, _alt] = _position) do
    if (lon >= 0.0 && lat >=0.0) do
      true
    else false
    end
  end

  # upload psoition to sondehub , stoes response and returns updated state
  def upload_new_position(state) do
    Sondehub.Listener.Impl.upload_listener(state.listener_data)
    |> handle_response(state) # updat state with response
  end

  def get_update_interval(state) do
    if state.listener_data[:mobile] do
      @listener_update_interval_mobile
    else
      @listener_update_interval_static
    end
  end
end
