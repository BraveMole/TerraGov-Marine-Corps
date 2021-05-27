
/obj/vehicle/unmanned
	name = "unmanned vehicle"
	desc = "A small remote-controllable vehicle, usually owned by the TGMC and other major armies."
	icon = 'icons/obj/unmanned_vehicles.dmi'
	icon_state = "light_uv"
	anchored = FALSE
	buckle_flags = null
	light_range = 6
	light_power = 3
	light_system = MOVABLE_LIGHT
	move_delay = 1.8	//set this to limit the speed of the vehicle
	max_integrity = 300
	resistance_flags = XENO_DAMAGEABLE
	flags_atom = BUMPABLE
	///Type of "turret" attached
	var/turret_type
	///Turret types we're allowed to attach
	var/turret_pattern = PATTERN_TRACKED
	///Boolean: do we want this turret to draw overlays for itself?
	var/overlay_turret = TRUE
	///Delay in byond ticks between weapon fires
	var/fire_delay = 5
	///Ammo remaining for the robot
	var/current_rounds = 0
	///max ammo the robot can hold
	var/max_rounds = 300
	///Buller type we fire, declared as type but set to a reference in Initialize
	var/datum/ammo/bullet/ammo = /datum/ammo/bullet/smg
	///The currently loaded and ready to fire projectile
	var/obj/projectile/in_chamber = null
	///Sound file or string type for playing the shooting sound
	var/gunnoise = "gun_smartgun"
	/// The camera attached to the vehicle
	var/obj/machinery/camera/camera
	/// Serial number of the vehicle
	var/static/serial = 1
	/// If the vehicle should spawn with a weapon allready installed
	var/obj/item/uav_turret/spawn_equipped_type = null
	COOLDOWN_DECLARE(fire_cooldown)

/obj/vehicle/unmanned/Initialize()
	. = ..()
	current_rounds = max_rounds
	ammo = GLOB.ammo_list[ammo]
	name += " " + num2text(serial)
	serial++
	GLOB.unmanned_vehicles += src
	camera = new
	camera.network += list("marine")
	if(spawn_equipped_type)
		turret_type = initial(spawn_equipped_type.turret_type)
		ammo = GLOB.ammo_list[initial(spawn_equipped_type.ammo_type)]
		update_icon()


/obj/vehicle/unmanned/Destroy()
	. = ..()
	QDEL_NULL(camera)
	GLOB.unmanned_vehicles -= src

/obj/vehicle/unmanned/update_overlays()
	. = ..()
	if(!overlay_turret)
		return
	switch(turret_type)
		if(TURRET_TYPE_HEAVY)
			. += image('icons/obj/unmanned_vehicles.dmi', src, "heavy_cannon")
		if(TURRET_TYPE_LIGHT)
			. += image('icons/obj/unmanned_vehicles.dmi', src, "light_cannon")
		if(TURRET_TYPE_EXPLOSIVE)
			. += image('icons/obj/unmanned_vehicles.dmi', src, "bomb")
		if(TURRET_TYPE_DROIDLASER)
			. += image('icons/obj/unmanned_vehicles.dmi', src, "droidlaser")

/obj/vehicle/unmanned/examine(mob/user, distance, infix, suffix)
	. = ..()
	if(ishuman(user))
		to_chat(user, "It has [current_rounds] out of [max_rounds] ammo left.")

/obj/vehicle/unmanned/attackby(obj/item/I, mob/user, params)
	. = ..()
	if(!istype(I, /obj/item/uav_turret) && !istype(I, /obj/item/explosive/plastique))
		return
	if(turret_type)
		to_chat(user, "<span class='notice'>There's already something attached!</span>")
		return
	if(istype(I, /obj/item/uav_turret))
		var/obj/item/uav_turret/turret = I
		if(turret_pattern != turret.turret_pattern)
			to_chat(user, "<span class='notice'>You can't attach that type of turret!</span>")
			return
	user.visible_message("<span class='notice'>[user] starts to attach [I] to [src].</span>",
	"<span class='notice'>You start to attach [I] to [src].</span>")
	if(!do_after(user, 3 SECONDS, TRUE, src, BUSY_ICON_GENERIC))
		return
	if(istype(I, /obj/item/uav_turret))
		var/obj/item/uav_turret/turret = I
		turret_type = turret.turret_type
		ammo = GLOB.ammo_list[turret.ammo_type]
	else if(istype(I, /obj/item/explosive/plastique))
		turret_type = TURRET_TYPE_EXPLOSIVE
	user.visible_message("<span class='notice'>[user] attaches [I] to [src].</span>",
	"<span class='notice'>You attach [I] to [src].</span>")
	update_icon()
	SEND_SIGNAL(src, COMSIG_UNMANNED_TURRET_UPDATED, turret_type)
	qdel(I)

/**
 * Called when the drone is unlinked from a remote control
 * Only argument is the remote it was linked to
 */
/obj/vehicle/unmanned/proc/on_link()
	RegisterSignal(src, COMSIG_REMOTECONTROL_CHANGED, .proc/on_remote_toggle)

/**
 * Called when the drone is linked to a remote control
 * Only argument is the remote it is linked to
 */
/obj/vehicle/unmanned/proc/on_unlink()
	UnregisterSignal(src, COMSIG_REMOTECONTROL_CHANGED)

///Called when remote control is taken
/obj/vehicle/unmanned/proc/on_remote_toggle(datum/source, is_on, mob/user)
	SIGNAL_HANDLER
	set_light_on(is_on)

///Checks if we can or already have a bullet loaded that we can shoot
/obj/vehicle/unmanned/proc/load_into_chamber()
	if(in_chamber)
		return TRUE //Already set!
	if(current_rounds <= 0)
		return FALSE
	in_chamber = new /obj/projectile(src) //New bullet!
	in_chamber.generate_bullet(ammo)
	return TRUE


///Check if we have/create a new bullet and fire it at an atom target
/obj/vehicle/unmanned/proc/fire_shot(atom/target, mob/user)
	if(!COOLDOWN_CHECK(src, fire_cooldown))
		return FALSE
	if(load_into_chamber() && istype(in_chamber, /obj/projectile))
		//Setup projectile
		in_chamber.original_target = target
		in_chamber.def_zone = pick("chest","chest","chest","head")
		//Shoot at the thing
		playsound(loc, gunnoise, 75, 1)
		in_chamber.fire_at(target, src, null, ammo.max_range, ammo.shell_speed)
		in_chamber = null
		COOLDOWN_START(src, fire_cooldown, fire_delay)
		current_rounds--
	return TRUE

/obj/vehicle/unmanned/medium
	name = "medium unmanned vehicle"
	icon_state = "medium_uv"
	move_delay = 2.4
	max_rounds = 200
	max_integrity = 500
	ammo = /datum/ammo/bullet/machinegun

/obj/vehicle/unmanned/heavy
	name = "heavy unmanned vehicle"
	icon_state = "heavy_uv"
	move_delay = 3.5
	max_rounds = 200
	max_integrity = 700
	anchored = TRUE
	ammo = /datum/ammo/bullet/machinegun
