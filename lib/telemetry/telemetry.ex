defmodule Sondehub.Telemetry do


  def start_link() do
    GenServer.start_link(Sondehub.Telemetry.Server,%{},[name: Telemetry])
  end

  def upload_telem_payload(payload) do
    # payload includes listener info
    GenServer.cast(Telemetry, {:upload_telem,payload})

  end

  def get_state() do
    GenServer.call(Telemetry,:get_state)

  end

  def last_resp() do
    GenServer.call(Telemetry,:last_resp)
  end
end
