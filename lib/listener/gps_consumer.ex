defmodule Listener.XGPS.Consumer do
  @moduledoc """
  The GenEvent handler implementation is a simple consumer.
  """
  use GenStage
  alias Sondehub.Listener
  @doc """
    {#PID<0.1827.0>,
    %XGPS.GpsData{
    has_fix: true,
    time: ~T[13:05:36.000000],
    date: ~D[2023-03-30],
    latitude: 53.226985666666664,
    longitude: -2.5065798333333333,
    geoidheight: {48.7, :meter},
    altitude: {58.6, :meter},
    speed: 4.452208,
    angle: nil,
    magvariation: nil,
    hdop: 1.11,
    fix_quality: 1,
    satelites: 11

  """

  def start_link() do
    GenStage.start_link(__MODULE__, :ok)
  end

  # Callbacks
  def init(:ok) do
    XGPS.Ports.start_port("ttyAMA0")

    # Starts a permanent subscription to the broadcaster
    # which will automatically start requesting items.
    {:consumer, :ok, subscribe_to: [XGPS.Broadcaster]}
  end

  @doc """
  This function will be called once for each report from the GPS.
  """
  def handle_events(events, _from, state) do
    for event <- events do
      test_me(event)

      {altitude,_units} = event.altitude
      if event.has_fix do
       set_position([event.latitude,event.longitude,altitude])
      end
      IO.inspect {self(), event}
      :ok
    end

    {:noreply, [], state}
  end
  def test_me(event) do
    IO.inspect(event.has_fix)
  end
    def set_position([_latitude,longitude,altitude]) do
      IO.puts("long - #{longitude}")
    end

end

