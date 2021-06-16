/**
 * This datum in charge with selecting wich loadout is currently being edited
 * It also contains a tgui to navigate beetween loadouts
 */
/datum/loadout_manager
	/// The data sent to tgui
	var/loadouts_data = list()
	/// The host of the loadout_manager, aka from which loadout vendor are you managing loadouts
	var/loadout_vendor 
	/// The version of the loadout manager
	var/version = 1

///Remove a loadout from the list.
/datum/loadout_manager/proc/delete_loadout(datum/loadout/loadout)
	for(var/i = 1 to length(loadouts_data) step 2)
		if(loadout.job == loadouts_data[i] && loadout.name == loadouts_data[i+1])
			loadouts_data -= loadouts_data[i+1]
			loadouts_data -= loadouts_data[i]
			return

///Add one loadout to the loadout data
/datum/loadout_manager/proc/add_loadout(datum/loadout/next_loadout)
	loadouts_data += next_loadout.job
	loadouts_data += next_loadout.name

/datum/loadout_manager/ui_interact(mob/living/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "LoadoutManager")
		ui.open()

/datum/loadout_manager/ui_state(mob/user)
	return GLOB.human_adjacent_state

/datum/loadout_manager/ui_host()
	return loadout_vendor

/// Wrapper proc to set the host of our ui datum, aka the loadout vendor that's showing us the loadouts
/datum/loadout_manager/proc/set_host(_loadout_vendor)
	loadout_vendor = _loadout_vendor
	RegisterSignal(loadout_vendor, COMSIG_PARENT_QDELETING, .proc/close_ui)

/// Wrapper proc to handle loadout vendor being qdeleted while we have loadout manager opened
/datum/loadout_manager/proc/close_ui()
	SIGNAL_HANDLER
	ui_close()

/datum/loadout_manager/ui_data(mob/living/user)
	. = ..()
	var/data = list()
	var/list/loadouts_data_tgui = list()
	for(var/i = 1 to length(loadouts_data) step 2)
		var/next_loadout_data = list()
		next_loadout_data["job"] = loadouts_data[i]
		next_loadout_data["name"] = loadouts_data[i+1]
		loadouts_data_tgui += list(next_loadout_data)
	data["loadout_list"] = loadouts_data_tgui
	return data

/datum/loadout_manager/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	if(TIMER_COOLDOWN_CHECK(ui.user, COOLDOWN_LOADOUT_VISUALIZATION))
		return
	TIMER_COOLDOWN_START(ui.user, COOLDOWN_LOADOUT_VISUALIZATION, 1 SECONDS) //Anti spam cooldown
	switch(action)
		if("saveLoadout")
			if(length(loadouts_data) >= MAXIMUM_LOADOUT * 2)
				to_chat(ui.user, "<span class='warning'>You've reached the maximum number of loadouts saved, please delete some before saving new ones</span>")
				return
			var/loadout_name = params["loadout_name"]
			if(isnull(loadout_name))
				return
			var/loadout_job = params["loadout_job"]
			var/datum/loadout/loadout = create_empty_loadout(loadout_name, loadout_job)
			loadout.save_mob_loadout(ui.user)
			ui.user.client.prefs.save_loadout(loadout)
			add_loadout(loadout)
			update_static_data(ui.user, ui)
			loadout.loadout_vendor = loadout_vendor
			loadout.ui_interact(ui.user)
		if("importLoadout")
			var/loadout_id = params["loadout_id"]
			if(isnull(loadout_id))
				return
			var/list/items = splittext(loadout_id, "//")
			if(length(items) != 3)
				to_chat(ui.user, "<span class='warning'>Wrong format!</span>")
				return
			var/datum/loadout/loadout = load_player_loadout(items[1], items[2], items[3])
			if(!istype(loadout))
				to_chat(ui.user, "<span class='warning'>Loadout not found!</span>")
				return
			ui.user.client.prefs.save_loadout(loadout)
			add_loadout(loadout)
			update_static_data(ui.user, ui)
			loadout.loadout_vendor = loadout_vendor
			loadout.ui_interact(ui.user)
		if("selectLoadout")
			var/job = params["loadout_job"]
			var/name = params["loadout_name"]
			if(isnull(name))
				return
			var/datum/loadout/loadout = ui.user.client.prefs.load_loadout(name, job)
			if(!loadout)
				to_chat(ui.user, "<span class='warning'>Error when loading this loadout</span>")
				delete_loadout(name, job)
				CRASH("Fail to load loadouts")
			loadout.loadout_vendor = loadout_vendor
			loadout.ui_interact(ui.user)
			

/datum/loadout_manager/ui_close(mob/user)
	. = ..()
	user.client?.prefs.save_loadout_manager()
