defmodule TrackerOptions do
@moduledoc """
process the optional fields in the payload if they exist
they are identified by a keystring as the last field in the payload beginning with "012345"
return a list of sondehub keys and parsed values
if the keys do not exist return an empty list
"""

    @option_map %{
        "6" => {:sats,:int},
        "7" => {:vel_h,:float},
        "8" => {:heading,:float},
        "9" => {:batt,:float},
        "A" => {:temp,:float},
        "B" => {:ext_temperature,:float},
        "C" => {:pred_lat,:float},
        "D" => {:pred_lon,:float},
        "R" => {:pressure,:float},
        "S" => {:humidity,:float},
    }

    def get_options(), do: @option_map
    #"f1,f2,f3,f4,f5,f6,sats,speed,heading,temp,ext_temp,pressure,012345678ABR*123"
    def get_test_str(), do: "f1,f2,f3,f4,f5,f6,5,10.5,180.0,3340,20.0,15.0,1016.0,0123456789ABR*123"
    def get_test_str1(), do: "f1,f2,f3,f4,f5,f6,5,10.5,180.0,3340,20.0,15.0,1016.0*123"

    def process_extra_fields(str) do
        parse_payload(String.contains?(str,"012345"),str)
    end

    # no extra fields found
    def parse_payload(false,_payload) do
      []
    end

    def parse_payload(true,payload) do
        [payload_str,_] = String.split(payload,"*")
        payload_list = String.split(payload_str,",") |> Enum.drop(6)
        # get the extra field keys from payload
        keys = String.codepoints(List.last(payload_list)) |> Enum.drop(6)
        get_parsed_list(payload_list |> List.delete_at(-1),keys)
    end

    # get a list of keys and associated types e.[
  #  sats: :float,
  #  vel_h: :int,
  #  heading: :float.....

    def get_custom_keys(keys) do
        map = @option_map
        Enum.map(keys, fn k -> map[k] end)
        #|> Enum.zip(values)
    end

    def get_parsed_list(extra_fields,extra_keys) do
      # get a list of the fields we want with their types from the options map
      # and split keys and types into separate lists
      {keys,types} = get_custom_keys(extra_keys) |> Enum.unzip()

      #Create a list of the types and associated values
      # then parse each value according to type and return a list of parsed values
      parsed_values =
        Enum.zip(types,extra_fields)
        |> Enum.map(fn {t,v} -> parse_value({t,v}) end)

      # finally zip the keys with the values into a single (keyword) list
      Enum.zip(keys, parsed_values)
    end

    def parse_value({:float, value}) do
      {fvalue,_} = Float.parse(value)
      fvalue
    end

    def parse_value({:int, value}) do
      {ivalue,_} = Integer.parse(value)
      ivalue
    end


  end
