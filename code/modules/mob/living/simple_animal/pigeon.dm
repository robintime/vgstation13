//fucking kills myself

/mob/living/simple_animal/pigeon/New()
	..()
	if(!pigeoncolor)
		pigeonidle = pick( list("grey","white","brown") )
	if(!disposition)
		disposition = pick( list("mean","shy","lazy","carrier") )

/mob/living/simple_animal/pigeon
	name = "pigeon"
	real_name = "pigeon"
	desc = "The vermin of the skies."
	var/pigeoncolor
	var/disposition

//note to self: add more to description that changes based on disposition

	icon = 'icons/mob/pigeon.dmi'
	icon_state = "[pigeoncolor]pigeonidle"
	icon_living = "[pigeoncolor]pigeonidle"
	icon_dead = "[pigeoncolor]pigeondead"
	var/icon_sleep = "[pigeoncolor]pigeonsleep"

	health = 30
	maxHealth = 30
	gender = NEUTER
	size = SIZE_SMALL

	emote_sound = list("sound/voice/pigeoncoo.ogg","sound/voice/pigeoncoo2.ogg","sound/voice/pigeoncoo3.ogg")
	speak_chance = 1
	turns_per_move = 10
	speak_override = TRUE

	meat_type = /obj/item/weapon/reagent_containers/food/snacks/meat/animal/chicken
	holder_type = /obj/item/weapon/holder/animal/pigeon
	//??

	response_help  = "pets"
	response_disarm = "swats at"
	response_harm   = "hits"


	var/obj/item/inventory_head
	var/obj/item/inventory_back
	var/obj/item/clothing/mask/facehugger/facehugger
	var/list/spin_emotes = list("dances around","chases its tail")
	var/corgi_status = IDLE
	var/obj/movement_target
	var/mob/pointer_caller
	var/mob/master //Obtained randomly when petting him. Can be overriden.

	held_items = list()
	var/time_between_directed_steps = 6

/mob/living/simple_animal/corgi/has_hand_check()
	return 1 // can pull things with his mouth

/mob/living/simple_animal/corgi/Life()
	if(timestopped)
		return 0 //under effects of time magick
	spinaroo(spin_emotes)
	. = ..()
	if(.)
		regular_hud_updates()
		standard_damage_overlay_updates()
	if(!stat && !resting && !locked_to && (ckey == null)) //Behavior mechanisms (om nom :3)
		if(corgi_status == IDLE)
			get_target()
			stop_automated_movement = 0

		else if(corgi_status == BEGIN_FOOD_HUNTING)
			corgi_status = FOOD_HUNTING
			spawn(0) // Separate process
				stop_automated_movement = 1
				var/failedsteps = 0
				var/infinite_chase = loc && locate(/obj/machinery/power/treadmill) in loc
				while(movement_target && !Adjacent(movement_target) && get_dist(src,movement_target) < 7 && corgi_status == FOOD_HUNTING && failedsteps <= 2)
					if(!step_towards(src,movement_target,1) && !infinite_chase)
						failedsteps += 1
					if(time_between_directed_steps >= 1)
						sleep(time_between_directed_steps)
					else
						sleep(1)
				if(movement_target)
					if(isturf(movement_target.loc) && src.Adjacent(movement_target))
						movement_target.attack_animal(src)
					else if(ishuman(movement_target.loc))
						if(prob(20))
							emote("me", 1, "stares at [movement_target.loc]'s [movement_target] with a sad puppy-face and whimpers.")
				corgi_status = IDLE
				movement_target = null

		else if(corgi_status == BEGIN_POINTER_FOLLOWING)
			corgi_status = POINTER_FOLLOWING
			if(prob(35) || (master != null && pointer_caller == master))
				spawn(0) // Separate process
					stop_automated_movement = 1
					var/failedsteps = 0
					while(failedsteps <= 3)
						if(!movement_target || src.Adjacent(movement_target) || get_dist(src, movement_target) >= 7)
							break
						if(!step_towards(src,movement_target,1))
							failedsteps++
						sleep(time_between_directed_steps)

					var/corg_her = "her"
					if(gender == MALE)
						corg_her = "his"
					if(movement_target)
						step_towards(src,movement_target,1)
						playsound(loc, 'sound/voice/corgibark.ogg', 80, 1)
						if(istype(movement_target,/obj/item/weapon/reagent_containers/food/snacks))
							emote("me", 1, "barks at [movement_target], as if begging it to go into [corg_her] mouth.")
							corgi_status = BEGIN_FOOD_HUNTING
						else if(ishuman(movement_target))
							emote("me", 1, "barks at [movement_target] and wags [corg_her] tail.")
							corgi_status = IDLE
						else
							emote("me", 1, "barks with an attitude!")
							corgi_status = IDLE

			else
				emote("me", 1, "stares into space with a blank expression.")
				corgi_status = IDLE

/mob/living/simple_animal/corgi/regular_hud_updates()
	if(fire_alert)
		throw_alert(SCREEN_ALARM_FIRE, fire_alert == 1 ? /obj/abstract/screen/alert/carbon/burn/ice/corgi : /obj/abstract/screen/alert/carbon/burn/fire/corgi)
	else
		clear_alert(SCREEN_ALARM_FIRE)
	update_pull_icon()
	if(oxygen_alert)
		throw_alert(SCREEN_ALARM_BREATH, /obj/abstract/screen/alert/carbon/breath/corgi)
	else
		clear_alert(SCREEN_ALARM_BREATH)
	if(toxins_alert)
		throw_alert(SCREEN_ALARM_TOXINS, /obj/abstract/screen/alert/tox/corgi)
	else
		clear_alert(SCREEN_ALARM_TOXINS)

	if(healths)
		switch(health)
			if(30 to INFINITY)
				healths.icon_state = "health0"
			if(26 to 29)
				healths.icon_state = "health1"
			if(21 to 25)
				healths.icon_state = "health2"
			if(16 to 20)
				healths.icon_state = "health3"
			if(11 to 15)
				healths.icon_state = "health4"
			if(6 to 10)
				healths.icon_state = "health5"
			if(1 to 5)
				healths.icon_state = "health6"
			else
				healths.icon_state = "health7"

/mob/living/simple_animal/corgi/show_inv(mob/user as mob)
	user.set_machine(src)
	if(user.stat)
		return

	var/dat
	if(inventory_head)
		dat +=	"<br><b>Head:</b> [inventory_head] (<a href='?src=\ref[src];remove_inv=head'>Remove</a>)"
	else
		dat +=	"<br><b>Head:</b> <a href='?src=\ref[src];add_inv=head'>Nothing</a>"
	if(inventory_back)
		dat +=	"<br><b>Back:</b> [inventory_back] (<a href='?src=\ref[src];remove_inv=back'>Remove</a>)"
	else
		dat +=	"<br><b>Back:</b> <a href='?src=\ref[src];add_inv=back'>Nothing</a>"

	dat += {"
	<BR>
	<BR><A href='?src=\ref[user];mach_close=mob\ref[src]'>Close</A>
	"}

	var/datum/browser/popup = new(user, "corgi\ref[src]", "[src]", 340, 500)
	popup.set_content(dat)
	popup.open()

/mob/living/simple_animal/corgi/attackby(var/obj/item/O as obj, var/mob/user as mob)
	if(istype(O, /obj/item/weapon/newspaper))
		if(!stat)
			user.visible_message("<span class='notice'>[user] baps [name] on the nose with the rolled up [O].</span>")
			spawn(0)
				emote("me", 1, "whines.")
				for(var/i in list(1,2,4,8,4,2,1,2))
					dir = i
					sleep(1)
	else if(inventory_head && inventory_back)
		//helmet and armor = 100% protection
		if( istype(inventory_head,/obj/item/clothing/head/helmet) && istype(inventory_back,/obj/item/clothing/suit/armor) )
			if( O.force )
				to_chat(usr, "<span class='warning'>[src] is wearing too much armor. You can't cause \him any damage.</span>")
				for (var/mob/M in viewers(src, null))
					M.show_message("<span class='danger'>[user] hits [src] with [O], however [src] is too armored.</span>")
			else
				to_chat(usr, "<span class='warning'>[src] is wearing too much armor. You can't reach \his skin.</span>")
				for (var/mob/M in viewers(src, null))
					M.show_message("<span class='warning'>[user] gently taps [src] with [O]. </span>")
			if(health>0 && prob(15))
				emote("me", 1, "looks at [user] with [pick("an amused","an annoyed","a confused","a resentful", "a happy", "an excited")] expression.")
			return
	else
		var/obj/item/clothing/mask/facehugger/F = O
		if(istype(F))
			user.drop_from_inventory(F)
			F.Attach(src)
			return
	..()

/mob/living/simple_animal/corgi/Topic(href, href_list)
	if(usr.stat)
		return

	if(!Adjacent(usr) || usr.incapacitated() || !(ishuman(usr) || ismonkey(usr) || isrobot(usr) ||  isalienadult(usr)))
		return

	//Removing from inventory
	if(href_list["remove_inv"])
		var/remove_from = href_list["remove_inv"]
		remove_inventory(remove_from,usr)
		show_inv(usr)

	//Adding things to inventory
	else if(href_list["add_inv"])
		var/add_to = href_list["add_inv"]
		if(!usr.get_active_hand())
			to_chat(usr, "<span class='warning'>You have nothing in your hand to put on its [add_to].</span>")
			return
		switch(add_to)
			if("head")
				place_on_head(usr.get_active_hand())

			if("back")
				if(inventory_back)
					to_chat(usr, "<span class='warning'>It's already wearing something.</span>")
					return
				else
					var/obj/item/item_to_add = usr.get_active_hand()

					if(!item_to_add)
						usr.visible_message("<span class='notice'>[usr] pets [src]</span>","<span class='notice'>You rest your hand on [src]'s back for a moment.</span>")
						return
					if(istype(item_to_add,/obj/item/weapon/c4)) // last thing he ever wears, I guess
						item_to_add.afterattack(src,usr,1)
						return

					if( ! ( item_to_add.type in valid_corgi_backpacks ) )
						to_chat(usr, "You set [item_to_add] on [src]'s back, but \he shakes it off!")
						usr.drop_item(item_to_add, get_turf(src))

						if(prob(25))
							step_rand(item_to_add)
						if (ckey == null)
							for(var/i in list(1,2,4,8,4,8,4,dir))
								dir = i
								sleep(1)
						return

					usr.drop_item(item_to_add, src, force_drop = 1)
					src.inventory_back = item_to_add
					if(isrig(item_to_add)) //TIME TO HACKINTOSH
						var/obj/item/clothing/head/helmet/space/rig/rig_helmet = new (src)
						place_on_head(rig_helmet)
					regenerate_icons()

		show_inv(usr)
	else
		..()

/mob/living/simple_animal/corgi/get_butchering_products()
	return list(/datum/butchering_product/skin/corgi, /datum/butchering_product/teeth/few)

/mob/living/simple_animal/corgi/proc/place_on_head(obj/item/item_to_add)
	if(istype(item_to_add,/obj/item/weapon/c4)) // last thing he ever wears, I guess
		item_to_add.afterattack(src,usr,1)
		return

	if(inventory_head)
		if(usr)
			to_chat(usr, "<span class='warning'>You can't put more than one hat on [src]!</span>")
		return
	if(!item_to_add)
		usr.visible_message("<span class='notice'>[usr] pets [src].</span>","<span class='notice'>You rest your hand on [src]'s head for a moment.</span>")
		return


	if(!(item_to_add.type in valid_corgi_hats))
		to_chat(usr, "You set [item_to_add] on [src]'s head, but \he shakes it off!")
		usr.drop_item(item_to_add, src.loc)

		if(prob(25))
			step_rand(item_to_add)
		if (ckey == null)
			for(var/i in list(1,2,4,8,4,8,4,dir))
				dir = i
				sleep(1)
		return

	if(istype(item_to_add,/obj/item/clothing/head))
		var/obj/item/clothing/head/hat = item_to_add
		if(hat.on_top)
			to_chat(usr, "You set [item_to_add] on [src]'s head, but it falls off from [src]'s restlessness!")
			usr.drop_item(item_to_add, src.loc)

			if(prob(25))
				step_rand(item_to_add)
			if (ckey == null)
				for(var/i in list(1,2,4,8,4,8,4,dir))
					dir = i
					sleep(1)
			return

	on_new_hat(item_to_add)//changes the corgi's name, description and behaviour to match their new hat

	if(usr)
		usr.visible_message("[usr] puts [item_to_add] on [real_name]'s head.  [src] looks at [usr] and barks once.",
			"You put [item_to_add] on [real_name]'s head.  [src] gives you a peculiar look, then wags \his tail once and barks.",
			"You hear a friendly-sounding bark.")
		usr.drop_item(item_to_add, src, force_drop = 1)
	else
		item_to_add.forceMove(src)
	src.inventory_head = item_to_add
	regenerate_icons()


/mob/living/simple_animal/corgi/proc/spinaroo(var/list/emotes)
    if(!stat && !resting && !locked_to)
        if(prob(1))
            if (ckey == null)
                emote("me", 1, pick(emotes))
                spawn(0)
                    for(var/i in list(1,2,4,8,4,2,1,2,4,8,4,2,1,2,4,8,4,2))
                        dir = i
                        sleep(1)

/mob/living/simple_animal/corgi/proc/reset_appearance()
	name = real_name
	desc = initial(desc)
	speak = list("YAP!", "Woof!", "Bark!", "Arf!")
	speak_emote = list("barks", "woofs")
	emote_hear = list("barks", "woofs", "yaps")
	emote_see = list("shakes its head", "shivers", "pants")
	emote_sound = list("sound/voice/corgibark.ogg")
	min_oxy = initial(min_oxy)
	minbodytemp = initial(minbodytemp)
	maxbodytemp = initial(maxbodytemp)
	set_light(0)

/mob/living/simple_animal/corgi/proc/remove_inventory(var/remove_from = "head", mob/user)
	switch(remove_from)
		if("head")
			if(inventory_head)
				if(isrighelmet(inventory_head) && inventory_back && isrig(inventory_back)) //You've activated my trap card!
					remove_inventory("back", user)
					return
				reset_appearance()
				inventory_head.forceMove(src.loc)
				inventory_head = null
				regenerate_icons()
			else
				if(user)
					to_chat(user, "<span class='warning'>There is nothing to remove from its [remove_from].</span>")
				return
		if("back")
			if(inventory_back)
				if(isrig(inventory_back) && inventory_head && isrighelmet(inventory_head)) //Now we undo the hack
					qdel(inventory_head)
					reset_appearance()
					inventory_head = null
				inventory_back.forceMove(src.loc)
				inventory_back = null
				regenerate_icons()
			else
				if(user)
					to_chat(user, "<span class='warning'>There is nothing to remove from its [remove_from].</span>")
				return

/mob/living/simple_animal/corgi/proc/get_target()
	var/vision_range = 5
	var/list/can_see = view(src, vision_range)
	for(var/obj/item/weapon/reagent_containers/food/snacks/S in can_see)
		if(isturf(S.loc) || ishuman(S.loc))
			movement_target = S
			corgi_status = BEGIN_FOOD_HUNTING
			return
	for(var/mob/living/carbon/M in can_see)
		for(var/obj/item/H in M.held_items)
			if(istype(H, /obj/item/weapon/reagent_containers/food/snacks))
				movement_target = H
				corgi_status = BEGIN_FOOD_HUNTING
				return

	for(var/obj/effect/decal/point/pointer in can_see)
		var/atom/pointer_target = pointer.target
		if(pointer_target == src)
			return
		corgi_status = BEGIN_POINTER_FOLLOWING
		pointer_caller = pointer.pointer
		movement_target = pointer_target
		return

/mob/living/simple_animal/corgi/Destroy()
	..()
	master = null
	pointer_caller = null
