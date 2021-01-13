/obj/machinery/computer
	name = "computer"
	icon = 'icons/obj/machines/computer.dmi'
	density = TRUE
	anchored = TRUE
	use_power = IDLE_POWER_USE
	layer = BELOW_OBJ_LAYER
	idle_power_usage = 300
	active_power_usage = 300
	var/processing = 0
	///How many times the computer can be smashed by a Xeno before it is disabled.
	var/durability = 2
	resistance_flags = UNACIDABLE

/obj/machinery/computer/Initialize()
	. = ..()
	start_processing()
	return INITIALIZE_HINT_LATELOAD

/obj/machinery/computer/LateInitialize()
	. = ..()
	power_change()

/obj/machinery/computer/examine(mob/user)
	. = ..()
	if(machine_stat & NOPOWER)
		to_chat(user, "<span class='warning'>It is currently unpowered.</span>")

	if(durability < initial(durability))
		to_chat(user, "<span class='warning'>It is damaged, and can be fixed with a welder.</span>")

	if(machine_stat & DISABLED)
		to_chat(user, "<span class='warning'>It is currently disabled, and can be fixed with a welder.</span>")

	if(machine_stat & BROKEN)
		to_chat(user, "<span class='warning'>It is broken and needs to be rebuilt.</span>")

/obj/machinery/computer/process()
	if(machine_stat & (NOPOWER|BROKEN|DISABLED))
		return 0
	return 1

/obj/machinery/computer/emp_act(severity)
	if(prob(20/severity)) set_broken()
	..()


/obj/machinery/computer/ex_act(severity)
	if(CHECK_BITFIELD(resistance_flags, INDESTRUCTIBLE))
		return FALSE
	switch(severity)
		if(EXPLODE_DEVASTATE)
			qdel(src)
			return
		if(EXPLODE_HEAVY)
			if (prob(25))
				qdel(src)
				return
			if (prob(50))
				for(var/x in verbs)
					verbs -= x
				set_broken()
		if(EXPLODE_LIGHT)
			if (prob(25))
				for(var/x in verbs)
					verbs -= x
				set_broken()


/obj/machinery/computer/bullet_act(obj/projectile/Proj)
	if(CHECK_BITFIELD(resistance_flags, INDESTRUCTIBLE))
		visible_message("[Proj] ricochets off [src]!")
		return 0
	else
		if(prob(round(Proj.ammo.damage /2)))
			set_broken()
		..()
		return 1

/obj/machinery/computer/update_icon()
	..()
	icon_state = initial(icon_state)

	// Broken
	if(machine_stat & (BROKEN|DISABLED))
		icon_state += "b"

	// Powered
	else if(machine_stat & NOPOWER)
		icon_state = initial(icon_state)
		icon_state += "0"

/obj/machinery/computer/proc/set_broken()
	machine_stat |= BROKEN
	density = FALSE
	update_icon()

/obj/machinery/computer/proc/decode(text)
	// Adds line breaks
	text = replacetext(text, "\n", "<BR>")
	return text

/obj/machinery/computer/welder_act(mob/living/user, obj/item/I)
	if(user.action_busy)
		return FALSE

	var/obj/item/tool/weldingtool/welder = I

	if(!machine_stat & DISABLED && durability == initial(durability))
		to_chat(user, "<span class='notice'>The [src] doesn't need welding!</span>")
		return FALSE

	if(!welder.tool_use_check(user, 2))
		return FALSE

	if(user.skills.getRating("engineer") < SKILL_ENGINEER_MASTER)
		user.visible_message("<span class='notice'>[user] fumbles around figuring out how to deconstruct [src].</span>",
		"<span class='notice'>You fumble around figuring out how to deconstruct [src].</span>")
		var/fumbling_time = 5 SECONDS * (SKILL_ENGINEER_MASTER - user.skills.getRating("engineer"))
		if(!do_after(user, fumbling_time, TRUE, src, BUSY_ICON_UNSKILLED))
			return

	user.visible_message("<span class='notice'>[user] begins repairing damage to [src].</span>",
	"<span class='notice'>You begin repairing the damage to [src].</span>")
	playsound(loc, 'sound/items/welder2.ogg', 25, 1)

	if(!do_after(user, 5 SECONDS, TRUE, src, BUSY_ICON_BUILD))
		return

	if(!welder.remove_fuel(2, user))
		to_chat(user, "<span class='warning'>Not enough fuel to finish the task.</span>")
		return TRUE

	user.visible_message("<span class='notice'>[user] repairs [src]'s damage.</span>",
	"<span class='notice'>You repair [src].</span>")
	machine_stat &= ~DISABLED //Remove the disabled flag
	durability = initial(durability) //Reset its durability to its initial value
	update_icon()
	playsound(loc, 'sound/items/welder2.ogg', 25, 1)

/obj/machinery/computer/attackby(obj/item/I, mob/user, params)
	. = ..()

	if(isscrewdriver(I) && circuit)
		if(user.skills.getRating("engineer") < SKILL_ENGINEER_MASTER)
			user.visible_message("<span class='notice'>[user] fumbles around figuring out how to deconstruct [src].</span>",
			"<span class='notice'>You fumble around figuring out how to deconstruct [src].</span>")
			var/fumbling_time = 50 * ( SKILL_ENGINEER_MASTER - user.skills.getRating("engineer") )
			if(!do_after(user, fumbling_time, TRUE, src, BUSY_ICON_UNSKILLED))
				return

		playsound(loc, 'sound/items/screwdriver.ogg', 25, 1)

		if(!do_after(user, 20, TRUE, src, BUSY_ICON_BUILD))
			return

		var/obj/structure/computerframe/A = new(loc)
		var/obj/item/circuitboard/computer/M = new circuit(A)
		A.circuit = M
		A.anchored = TRUE

		for(var/obj/C in src)
			C.forceMove(loc)

		if(machine_stat & BROKEN)
			to_chat(user, "<span class='notice'>The broken glass falls out.</span>")
			new /obj/item/shard(loc)
			A.state = 3
			A.icon_state = "3"
		else
			to_chat(user, "<span class='notice'>You disconnect the monitor.</span>")
			A.state = 4
			A.icon_state = "4"

		M.decon(src)
		qdel(src)

	else if(isxeno(user))
		return attack_alien(user)

	else
		return attack_hand(user)


/obj/machinery/computer/attack_hand(mob/living/user)
	. = ..()
	if(.)
		return
	if(ishuman(usr))
		pick(playsound(src, 'sound/machines/computer_typing1.ogg', 5, 1), playsound(src, 'sound/machines/computer_typing2.ogg', 5, 1), playsound(src, 'sound/machines/computer_typing3.ogg', 5, 1))

///So Xenos can smash computers out of the way without actually breaking them
/obj/machinery/computer/attack_alien(mob/living/carbon/xenomorph/X)
	if(resistance_flags & INDESTRUCTIBLE)
		to_chat(X, "<span class='xenowarning'>We're unable to damage this!</span>")
		return

	if(machine_stat & (BROKEN|DISABLED)) //If we're already broken or disabled, don't bother
		to_chat(X, "<span class='xenowarning'>This peculiar thing is already broken!</span>")
		return

	if(durability <= 0)
		set_disabled()
		to_chat(X, "<span class='xenowarning'>We smash the annoying device, disabling it!</span>")
	else
		durability--
		to_chat(X, "<span class='xenowarning'>We smash the annoying device!</span>")

	X.do_attack_animation(src, ATTACK_EFFECT_DISARM2) //SFX
	playsound(loc, pick('sound/effects/bang.ogg','sound/effects/metal_crash.ogg','sound/effects/meteorimpact.ogg'), 25, 1) //SFX
	Shake(4, 4, 2 SECONDS)
