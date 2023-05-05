defmodule SondehubTest do
  use ExUnit.Case
  doctest Sondehub.Listener



  test " set position is string" do
    assert Sondehub.Listener.set_position("123,456,789") ==  {:ok,"Binary/String 123,456,789"}
    assert Sondehub.Listener.set_position([123,456,78]) ==  {:ok,[123,456,78]}
    assert Sondehub.Listener.set_position(%{lat: 123,lon: 456,alt: 78}) ==  {:ok,%{lat: 123,lon: 456,alt: 78}}
    assert Sondehub.Listener.set_position(123) ==  {:error,"position of format 123 is not supported, it must be list of type [lng,lat,alt], XGPS_map or string"}
  end
  test " validate gps position" do

  Sondehub.Listener.ValidatePosition.validate_gps_coordinates([-180,-90,10])
  Sondehub.Listener.ValidatePosition.validate_gps_coordinates([180,90,10])
  Sondehub.Listener.ValidatePosition.validate_gps_coordinates([181,91,10])
  Sondehub.Listener.ValidatePosition.validate_gps_coordinates([-181,-91,10])
  Sondehub.Listener.ValidatePosition.validate_gps_coordinates([0,0,10])

  Sondehub.Listener.ValidatePosition.validate_gps_coordinates([])
  end
end
