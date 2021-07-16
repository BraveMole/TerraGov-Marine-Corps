SUBSYSTEM_DEF(weeds)
	name = "Weed"
	priority = FIRE_PRIORITY_WEED
	runlevels = RUNLEVEL_LOBBY|RUNLEVEL_SETUP|RUNLEVEL_GAME|RUNLEVEL_POSTGAME
	wait = 5 SECONDS

	// This is a list of nodes on the map.
	var/list/creating = list()
	var/list/pending = list()
	var/list/currentrun

/datum/controller/subsystem/weeds/stat_entry()
	return ..("Nodes: [length(pending)]")

/datum/controller/subsystem/weeds/fire(resumed = FALSE)
	if(!resumed)
		currentrun = pending.Copy()
		creating = list()

	for(var/A in currentrun)
		if(MC_TICK_CHECK)
			return

		var/obj/effect/alien/weeds/node/N = currentrun[A]
		currentrun -= A
		var/turf/T = A

		if(QDELETED(N) || QDELETED(T))
			pending -= T
			continue

		if (locate(/obj/effect/alien/weeds/node) in T)
			pending -= T
			continue

		if (!T.is_weedable())
			pending -= T
			continue

		for(var/direction in GLOB.cardinals)
			var/turf/AdjT = get_step(T, direction)
			if (!(AdjT in N.node_turfs)) // only count our weed graph as eligble
				continue
			if (!(locate(/obj/effect/alien/weeds) in AdjT))
				continue

			creating[T] = N
			break


	// We create weeds outside of the loop to not influence new weeds within the loop
	for(var/turf/T AS in creating)
		if(MC_TICK_CHECK)
			return
		// Adds a bit of jitter to the spawning weeds.
		addtimer(CALLBACK(src, .proc/create_weed, T, creating[T]), rand(1, 3 SECONDS))
		pending -= T
		creating -= T



/datum/controller/subsystem/weeds/proc/add_node(obj/effect/alien/weeds/node/node)
	if(!node)
		stack_trace("SSweed.add_node called with a null obj")
		return FALSE

	for(var/turf/T AS in node.node_turfs)
		var/obj/effect/alien/weeds/weed = locate() in T
		if(weed?.type == node.weed_type)
			weed.parent_node = node
			continue
		if(weed && get_dist(node, weed) >= get_dist(weed.parent_node, weed))
			continue
		if(pending[T] && (get_dist(node, T) >= get_dist(pending[T], T)))
			continue
		pending[T] = node

/datum/controller/subsystem/weeds/proc/create_weed(turf/T, obj/effect/alien/weeds/node/node)
	if(QDELETED(node))
		return

	if(iswallturf(T))
		new /obj/effect/alien/weeds/weedwall(T)
		return

	for (var/obj/O in T)
		if(istype(O, /obj/structure/window/framed))
			new /obj/effect/alien/weeds/weedwall/window(T)
			return
		else if(istype(O, /obj/structure/window_frame))
			new /obj/effect/alien/weeds/weedwall/frame(T)
			return
		else if(istype(O, /obj/machinery/door) && O.density)
			return
		else if(istype(O, /obj/effect/alien/weeds) && !istype(O, /obj/effect/alien/weeds/node))
			qdel(O)
	new node.weed_type(T, node)
