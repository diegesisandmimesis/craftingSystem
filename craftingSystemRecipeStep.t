#charset "us-ascii"
//
// craftingSystemRecipeStep.t
//
#include <adv3.h>
#include <en_us.h>

#include "craftingSystem.h"

class RecipeStep: CraftingSystemObject
	syslogID = 'RecipeStep'

	rule = nil

	createRule() {}

	recipeAction() {}

        isReversible() { return((reversible == true) ? true : nil); }

        listRecipeStep() {}
        printStateMachine() {}
;
