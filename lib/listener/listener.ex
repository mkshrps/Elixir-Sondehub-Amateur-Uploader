defmodule Sondehub.Listener do
  use GenServer   # just need this for childSpec for now

  alias Sondehub.Listener
  @server Sondehub.Listener.Server
  @server_name Listener

  def start_link(opts \\ []) do
    # opts contains all Listener config values : see listener_info()
    GenServer.start_link(@server,opts,[name: @server_name, debug: [:trace]])
  end

  # [lat: 0.0,lon: 0.0, alt: 0]
  def set_position(position) when is_list(position) do
    GenServer.cast(@server_name,{:set_position_from_list, position})
    {:ok,position}
  end

  # map from GPS coordinate
  def set_position(gps_data) when is_map(gps_data) do
    GenServer.cast(@server_name,{:set_position_from_gps, gps_data})
    {:ok,gps_data}
  end

  # JSON string input data from MQTT
  def set_position(position) when is_binary(position) do
    GenServer.cast(@server_name,{:set_position_from_json, position})
    {:ok,"Binary/String #{position}"}
  end

  def set_position(position) do
    {:error, "position of format #{position} is not supported, it must be list of type [lng,lat,alt], XGPS_map or string"}
  end


  def get_position() do
    GenServer.call(@server_name,:get_position)
  end


  def set_callsign(callsign) do
    GenServer.call(@server_name,{:set_callsign, callsign})
  end

  def set_mobile(mobile) do
   GenServer.call(@server_name,{:set_mobile, mobile})
  end


end
