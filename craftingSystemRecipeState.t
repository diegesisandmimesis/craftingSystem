#charset "us-ascii"
//
// craftingSystemRecipeState.t
//
#include <adv3.h>
#include <en_us.h>

#include "craftingSystem.h"

class RecipeState: State, CraftingSystemObject
	syslogID = 'RecipeState'
	syslogFlag = 'RecipeState'

	recipe = nil
;

class RecipeTransition: Transition, CraftingSystemObject
	syslogID = 'RecipeTransition'
	syslogFlag = 'RecipeTransition'

	transitionAction() {
		consumeIngredients();
		recipeAction();
	}

	consumeIngredients() {}

	recipeAction() {
		recipeStep.recipeAction();
	}
	beforeTransition() { "beforeTransition()\n "; }
	afterTransition() { "afterTransition()\n "; }
;

class RecipeEnd: RecipeTransition
	consumeIngredients() {
		recipe.consumeIngredients();
	}

	afterTransition() {
_debug('afterTransition()');
		recipe.produceResult();
	}
;
