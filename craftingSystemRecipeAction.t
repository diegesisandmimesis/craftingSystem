#charset "us-ascii"
//
// craftingSystemRecipeAction.t
//
#include <adv3.h>
#include <en_us.h>

#include "craftingSystem.h"

class RecipeAction: RecipeStep
	syslogID = 'RecipeAction'

	srcObject = nil
	dstObject = nil
	action = nil

	recipe = nil

	reversible = nil

	initializeRecipeStep() {
		if((location == nil) || !location.ofKind(Recipe))
			return;
		location.addRecipeStep(self);
		recipe = location;
	}

	getConfig() {
		local r;

		r = object {};

		r.srcObject = srcObject;
		r.dstObject = dstObject;
		r.action = action;

		return(r);
	}

	isReversible() { return((reversible == true) ? true : nil); }

	recipeAction() {}

	listRecipeStep() {}
	printStateMachine() {}
;
