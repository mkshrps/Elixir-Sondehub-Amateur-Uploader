
defmodule ParseTimedate do

  def set_current_date_time(kw_list,key) do
    {:ok,now} = DateTime.now("Etc/UTC")

    {_,list} =  Keyword.get_and_update(kw_list,key, fn current -> {current,"#{now}"} end)
    list
  end

  def add_date_to_time1(kw_list,key) do
    # get the received time
    {:ok,tm} = Keyword.fetch(kw_list,key)
    # date is now unless just gone midnight (not bothered)
    dt = DateTime.to_date(DateTime.now("Etc/UTC"))
    # create a formatted date and time
    {_,list} =  Keyword.get_and_update(kw_list,:time_received, fn current -> {current,"#{dt} #{tm}Z"} end)
    list
  end
  # convert "hh:mm:ss" to [h,m,s]
  def time_string_to_list(ts) do
    timelist = String.split(ts,":")
    Enum.map(timelist, fn s -> String.to_integer(s) end)
  end

  # dt is DateTime struct from DateTime.now("Etc/UTC) for example
  def update_time_in_dt(dt, timestring) do
    # convert timestring to list of integers
    [hour,min,sec] = time_string_to_list(timestring)
    # and update the date time struct
    %{dt | :hour => hour, :minute => min, :second => sec}
  end

  def add_date_to_time(list,key ) do
    # get current dt
    {:ok,now} = DateTime.now("Etc/UTC")
    # get the new time from the list/key
    timestring = Keyword.get(list,key)
    # put the new time into the dt struct
    now = update_time_in_dt(now, timestring)
    # regenerate the list with a complete iso8601 date_time string
    {_,list} = Keyword.get_and_update(list,key, fn current -> {current, DateTime.to_iso8601(now)} end)
    list
  end

end
