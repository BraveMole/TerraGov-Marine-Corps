/mob/living/carbon/xenomorph/boiler
	caste_base_type = /mob/living/carbon/xenomorph/boiler
	name = "Boiler"
	desc = "A huge, grotesque xenomorph covered in glowing, oozing acid slime."
	icon = 'icons/Xeno/2x2_Xenos.dmi'
	icon_state = "Boiler Walking"
	health = 200
	maxHealth = 200
	plasma_stored = 450
	pixel_x = -16
	old_x = -16
	mob_size = MOB_SIZE_BIG
	tier = XENO_TIER_THREE
	upgrade = XENO_UPGRADE_ZERO
	gib_chance = 100
	drag_delay = 6 //pulling a big dead xeno is hard
	light_power = 6
	light_range = 5
	var/datum/effect_system/smoke_spread/xeno/smoke

// ***************************************
// *********** Init
// ***************************************
/mob/living/carbon/xenomorph/boiler/Initialize()
	. = ..()
	smoke = new /datum/effect_system/smoke_spread/xeno/acid(src)
	ammo = GLOB.ammo_list[/datum/ammo/xeno/boiler_gas]
	RegisterSignal(src, COMSIG_XENOMORPH_GIBBING, .proc/gib_explode)


// ***************************************
// *********** Gibbing behaviour
// ***************************************
/mob/living/carbon/xenomorph/boiler/proc/gib_explode()
	SIGNAL_HANDLER
	visible_message("<span class='danger'>[src] begins to bulge grotesquely, and explodes in a cloud of corrosive gas!</span>")
	smoke.set_up(2, get_turf(src))
	smoke.start()
