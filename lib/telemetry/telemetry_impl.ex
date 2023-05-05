defmodule Sondehub.Telemetry.Impl do
  alias ParseTimedate
  alias Sondehub.Listener
  require Logger

  @moduledoc """
  Documentation for `Sondehub`.
  """


  @doc """
    Sondehub amatuer data  format
  [
    {
      "dev" ,
      "software_name" ,
      "software_version" ,
      "uploader_callsign" ,
      "time_received" "2023-02-13T154208.509Z",
      "payload_callsign" ,
      "datetime" "2023-02-13T154208.509Z",
      "lat" 0,
      "lon" 0,
      "alt" 0,
      "frequency" 0,
      "temp" 0,
      "humidity" 0,
      "vel_h" 0,
      "vel_v" 0,
      "pressure" 0,
      "heading" 0,
      "batt" 0,
      "sats" 0,
      "snr" 0,
      "rssi" 0,
      "uploader_position" [
        0,
        0,
        0
      ],
      "uploader_antenna"
    }
  ]


  @hab_keys_ext
  [
      :dev ,
      :software_name ,
      :software_version ,
      :uploader_callsign ,
      :time_received ,
      :payload_callsign ,
      :datetime,
      :lat ,
      :lon ,
      :alt ,
      :frequency ,
      :temp ,
      :humidity ,
      :vel_h ,
      :vel_v ,
      :pressure ,
      :heading ,
      :batt ,
      :sats ,
      :snr ,
      :rssi ,
      :uploader_position,
      :uploader_antenna
  ]
"""
  @standard_fields 6

  @hab_keys  [
      #:dev ,
      :payload_callsign ,
      :frame,
      :datetime,
      :lat ,
      :lon ,
      :alt
  ]

  @telemetry_url  "https://api.v2.sondehub.org/amateur/telemetry"
  @uploader_callsign "cransleigh_gateway"
  def uploader_callsign do @uploader_callsign end
  def hab_keys do @hab_keys end

  def lora_msg1() do
    ["$$FLOPPY450,0232,16:30:00,53.223841,-2.517784,44"]
  end

  def lora_msg() do
    # callsign,id,time,lat,lng,alt,
    "$$FLOPPY445,10716,13:57:10,53.226910,-2.506636,43,0,0,12,16,0.00, 0.00,0.00,3449,0,3,0*2B5F"

  end

  # ---------------- Upload Functions ------------------
  # payload_data ::
  # %{:raw_payload => , :snr => , :rssi => , :listener_info => }

  def upload_telemetry(payload_data) do
    Map.put(payload_data,:listener_info,Listener.Impl.listener_info())
    |> parse_msg()
    |> convert_to_json()
    |> send_telemetry_to_sondehub()
   # return the response HTTPoison.response struct
  end

  def send_telemetry_to_sondehub(json_upload) do
    url = @telemetry_url
    header = [{"content-type", "application/json"}]
    Logger.info(json_upload)
    HTTPoison.put(url,json_upload,header)
  end

  def convert_to_json(body) do
    # then to json
    {:ok,json_content} = JSON.encode(body)
    # wrap in [] for telemetry
    "[#{json_content}]"
  end


  # message processing funcs
  # parse the received (lora) message ind extra fields
  # into a keyword list for the uploader
  def parse_msg(%{:payload => payload,:snr => snr,:rssi => rssi, :frq => frq, :listener_info => listener_info } = _message_data) do
    payload
    |> lora_msg_to_list()
    |> get_standard_fields()  # just take standard fields out of payloadc for now
    |> add_keywords_to_list(hab_keys())
    |> add_custom_fields(IO.iodata_to_binary(payload))
    |> add_device_details(snr,rssi,frq/1.0E6,listener_info)
    |> ParseTimedate.set_current_date_time(:time_received)
    |> ParseTimedate.add_date_to_time(:datetime)
    |> parse_to_int(:frame)
    |> parse_to_float(:lon)
    |> parse_to_float(:lat)
    |> parse_to_int(:alt)
  end

  # no custom fields to process so just get the standard fields
  def get_standard_fields(fields_list) do
    Enum.take(fields_list,@standard_fields)
  end
  # todo process custom fields from lora payload
  # convert message to string for processing handle it as iodat or string
  # return a string
  def lora_msg_to_string(msg) when is_binary(msg) do
   msg
  end

#  def lora_msg_to_string(io_str) do
#    IO.iodata_to_binary(io_str)
#  end

  def lora_msg_id(lora_msg) do
    {id,_rest} = String.split(lora_msg,",")
    |> List.pop_at(1)
    String.to_integer(id)

  end
  # convert incoming telem message to string and then create a list on comma delimiter
  def lora_msg_to_list(io_list) do
      io_list
     |> IO.iodata_to_binary()
     |> String.trim("$$")
     |> String.split(",")
  end

  def add_device_details(lora_list,snr,rssi,frq,[]) do
    lst = [snr: snr, rssi: rssi, frequency: frq]
    lora_list ++ lst
  end

  # extra details to be addd to head of list (reverse order)
  def add_device_details(lora_list,snr,rssi,frq,listener_info) do
    lst = [snr: snr, rssi: rssi, frequency: frq]
    lora_list ++ lst ++ listener_info
  end

  #def hab_keys_ext do @hab_keys_ext end
  def add_keywords_to_list(hab_msg_list,hab_keys) do
    #create a keyword list
    Enum.zip(hab_keys,hab_msg_list)
  end

  def is_telem?(str_msg) do
    test = fn "$$" -> true
      _ -> false
    end
    test.(String.slice(str_msg,0..1))
  end

  def add_custom_fields(current_fields_list,lora_message) do
    current_fields_list ++ TrackerOptions.process_extra_fields(lora_message)
  end

  defp parse_to_int(list,key) do
    {_,list } = Keyword.get_and_update(list,key, fn c -> {c, String.to_integer(c)} end)
    list
    end

  defp parse_to_float(list,key) do
    # {_,list } = Keyword.get_and_update(list,key, fn c -> {c, Float.parse(c)} end)
    {_,list } = Keyword.get_and_update(list,key, fn c -> {v,_} = Float.parse(c); {c,v} end)

     list
  end

    # NOT USED -----------------------------------------
  # loop through a keyword list convert numeric strings to numbers
  defp parse_number(string_value) do
    result = Float.parse(string_value)
    if result == :error do
      string_value
    else
      {number,str} = result
      if str == "" do
        number
      else
        string_value
      end
    end
  end

  defp parse_list(list) do
    Enum.map(list, fn v -> parse_number(v) end)
  end


end
