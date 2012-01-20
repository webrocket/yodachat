require File.expand_path("../init", __FILE__)

Kosmonaut.debug = true
$worker = YodaChat::RoomWorker.new(ENV["KOSMONAUT_BACKEND_URL"])
$worker.listen
