/**
 * Allow to representate an uniform and its tie (webbings and such)
 * This is only able to represent /obj/item/clothing/under
 */
/datum/item_representation/uniform_representation
	var/datum/item_representation/tie/tie 

/datum/item_representation/uniform_representation/New(obj/item/item_to_copy)
	if(!item_to_copy)
		return
	if(!isuniform(item_to_copy))
		CRASH("/datum/item_representation/uniform_representation created from an item that is not an uniform")
	..()
	var/obj/item/clothing/under/uniform_to_copy = item_to_copy
	if(uniform_to_copy.hastie)
		tie = new /datum/item_representation/tie(uniform_to_copy.hastie)

/datum/item_representation/uniform_representation/instantiate_object(master)
	var/obj/item/clothing/under/uniform = ..()
	if(tie)
		tie.install_on_uniform(uniform)
	return uniform

/**
 * Allow to representate a tie (typically a webbing)
 * This is only able to represent /obj/item/clothing/tie/storage
 */
/datum/item_representation/tie
	///The storage of the tie
	var/datum/item_representation/storage/hold

/datum/item_representation/tie/New(obj/item/item_to_copy)
	if(!item_to_copy)
		return
	if(!istiestorage(item_to_copy))
		CRASH("/datum/item_representation/tie created from an item that is not a tie storage")
	..()
	var/obj/item/clothing/tie/storage/tie = item_to_copy
	hold = new /datum/item_representation/storage(tie.hold)
	
/datum/item_representation/tie/instantiate_object(master)
	var/obj/item/clothing/tie/storage/tie = ..()
	tie.hold = hold.instantiate_object(tie)
	return tie

///Attach the tie to a uniform
/datum/item_representation/tie/proc/install_on_uniform(obj/item/clothing/under/uniform)
	var/obj/item/clothing/tie/storage/tie = instantiate_object()
	tie.on_attached(uniform)
	uniform.hastie = tie
