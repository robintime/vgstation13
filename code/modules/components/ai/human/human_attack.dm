/datum/component/ai/melee/attack_human

/datum/component/ai/melee/attack_human/cmd_attack(atom/target)
	if(!can_attack(target))
		return FALSE
	var/mob/living/carbon/human/H = parent
	H.a_intent = I_HURT
	var/damage_type = H.invoke_event(/event/comp_ai_cmd_get_damage_type)
	// TODO make it target the correct def_zone
	H.invoke_event(/event/comp_ai_cmd_evaluate_target, list("target" = target, "damage_type" = damage_type))
	H.ClickOn(target)
	return TRUE
