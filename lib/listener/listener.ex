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
  def set_position(position) do
    GenServer.cast(@server_name,{:set_position, position})
  end

  def set_callsign(callsign) do
    GenServer.call(@server_name,{:set_callsign, callsign})
  end

  def set_mobile(mobile) do
   GenServer.call(@server_name,{:set_mobile, mobile})
  end


end
