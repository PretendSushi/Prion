extends Node

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		CustomStatTracker.add_time_played()
		CustomStatTracker.save()
