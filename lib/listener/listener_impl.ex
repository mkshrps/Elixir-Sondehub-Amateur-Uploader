defmodule Sondehub.Listener.Impl do

   @moduledoc """
  Documentation for `Sondehub`.
  """


  @doc """
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
  @listener_url "https://api.v2.sondehub.org/amateur/listeners"
  @listener_data [
  software_name: "Elixir Gateway" ,
  software_version: "1.0.1",
  uploader_callsign: "weirdie_gateway",
  uploader_position: [53.230841,-2.527784,14],
  uploader_antenna: "Diamond 500",
  uploader_contact_email: "",
  mobile: true,
  ]

  def listener_info do @listener_data end

  def position(listener) do
    Keyword.get(listener,:uploader_position)
  end

  # parameters posn = [lon,lat,alt]
  def update_position(listener,posn) do
    {_,list} = Keyword.get_and_update(listener,:uploader_position, fn value -> {value, posn} end )
    list
  end

  # on_off = true/false
  def mobile(listener, on_off) when is_boolean(on_off) do
    {_,list} = Keyword.get_and_update(listener,:mobile, fn value -> {value,on_off} end )
    list
  end

    def values() do
      [0,0,0,[0,0,0],0,0,true]
    end

  def add_keywords_to_list(msg_list,keys) do
    #create a keyword list
    Enum.zip(keys,msg_list)
  end

  # listener is keyword list with listener data
  def upload_listener(listener) do
    listener
    |> convert_to_json()
    |> send_listener_to_sondehub()
   # return the response HTTPoison.response struct
  end

  def send_listener_to_sondehub(json_upload) do
    url = @listener_url
    header = [{"content-type", "application/json"}]
    HTTPoison.put(url,json_upload,header)
  end

  def convert_to_json(body) do
    # then to json
    {:ok,json_content} = JSON.encode(body)
    json_content
  end


end
