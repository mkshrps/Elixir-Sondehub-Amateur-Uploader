defmodule Sondehub.Telemetry.Server do
  use GenServer
  alias Sondehub.Telemetry.Impl
  require Logger

  # server callbacks
  def init([]) do
    #new_state = Map.put_new(state,:last_response,nil)
    new_state = %{
      :last_response => %{:status_code => 0, :status_msg => ""},
      :telemetry_data => %{:received_payload => [],:snr => 0.0,:rssi => 0, :frq => 0.0 , :listener_info => [], :custom => []}
    }
    {:ok,new_state}
  end

  def handle_cast({:upload_telem,telemetry_data},state) do

    {:ok,response} = Impl.upload_telemetry(telemetry_data)
    Logger.info(inspect(response))
    # update with response from attempted upload
    new_state = put_in(state.telemetry_data,telemetry_data)
    new_state = put_in(new_state.last_response.status_code, response.status_code)
    new_state = put_in(new_state.last_response.status_msg, response.body )
    {:noreply,new_state}
  end

  def handle_call(:last_resp,_from,state) do
    {:reply,state.last_response,state}
  end

  def handle_call(:get_state,_from,state) do
    {:reply,state, state}
  end



end
