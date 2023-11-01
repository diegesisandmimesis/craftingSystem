#charset "us-ascii"
//
// craftingSystemAction.t
//
#include <adv3.h>
#include <en_us.h>

#include "craftingSystem.h"

/*
modify playerActionMessages
	cantCraftThat = '{You/He} can\'t <<gAction.craftingVerb>> that. '
	cantCraftThatDontKnow = '{You/He} {do}n\'t know how to
		<<gAction.craftingVerb>> that. '
	cantCraftObj(obj) {
		return('{You/he} can\'t <<gAction.craftingVerb>>
			<<obj.name>>. ');
	}

	cantCraftHere = '{You/He} can\'t do that here. '
;
*/

canCraftHere: PreCondition
	checkPreCondition(obj, allowImplicit) {
		if(gAction.craftingLocation == nil)
			return;

		if(!gActor.isIn(gAction.craftingLocation)) {
			reportFailure(gAction.cantCraftHere);
			exit;
		}
	}
;

canCraft: PreCondition
	verifyPreCondition(obj) {
		if(obj == nil)
			obj = gDobj;
		if(obj.ofKind(RecipeUnthing))
			illogical(gAction.cantCraftObj(obj));
		else
			illogical(gAction.cantCraftThat);
	
	}
;

class _CraftAction: Action;

class CraftAction: _CraftAction, TAction
	preCond = [ canCraftHere, canCraft ]

	// If defined, this action can only be done in the given location.
	craftingLocation = nil

	// Verb to use in informational messages:  "You can't craft that. "
	// and so on.
	craftingVerb = 'craft'

	// Add RecipeUnthing instances to crafting actions' default scope.
	objInScope(obj) {
		local r;

		r = inherited(obj);
		if(r == true)
			return(true);

		if(obj.ofKind(RecipeUnthing))
			return(true);

		return(nil);
	}

	// Location-based crafting failure message.  This is what's
	// displayed when the craftingLocation check fails.
	cantCraftHere = '{You/he} can\'t <<craftingVerb>> here. '

	// 
	cantCraftObj(obj) {
		return('{You/he} can\'t <<craftingVerb>> <<obj.name>>. ');
	}

	// Generic failure message.  
	cantCraftThat = '{You/He} can\'t <<craftingVerb>> that. '
;
