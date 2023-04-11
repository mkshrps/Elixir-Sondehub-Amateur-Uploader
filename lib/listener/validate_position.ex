defmodule Listener.ValidatePosition do

  def parse_position([lat,lon,alt]) do
    [lat,lon,alt]
  end

  def parse_position([lat: lat,llon: lon, alt: alt]) do
    [lat,lon,alt]
  end

  def parse_position(position) when is_binary(position) do
      # parse a string assuming format "lng = 123,lng = 456, alt = 78"
    values =
    position
    |> String.replace(" ","",[global: true])
    |> String.split(",")
    |> Enum.map(fn pos -> [k,v] = String.split(pos,"=");{String.to_atom(k),v}  end)
    lng = Keyword.get(values,:lng)
    lat = Keyword.get(values,:lat)
    alt = Keyword.get(values,:alt)
    [lat, lon, alt]

  end

  def parse_position(position) when is_map(position) do
        %{ lat: lat, lon: lon, alt: alt} = position
        [lat,lon,alt]
  end

  # pass back invalid position
  def parse_position(_position) do
        []
  end


  def validate_gps_coordinates([lat,lon,_alt] )   do
    abs(lat) <= 90 && abs(lon) <= 180
  end

  def validate_gps_coordinates(_)   do
    false
  end




end
