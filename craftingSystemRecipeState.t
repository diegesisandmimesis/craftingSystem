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

	_ruleEngineInitFlag = true

	recipe = nil
;

class RecipeTransition: Transition, CraftingSystemObject
	syslogID = 'RecipeTransition'
	syslogFlag = 'RecipeTransition'

	_ruleEngineInitFlag = true

	transitionAction() {
		consumeIngredients();
		recipeAction();
	}

	consumeIngredients() {}

	recipeAction() {
		recipeStep.recipeAction();
	}
;

class RecipeNoTransition: NoTransition, CraftingSystemObject

	transitionAction() {
		recipeAction();
	}
	recipeAction() {
		recipeStep.recipeAction();
	}
;

class RecipeEnd: RecipeTransition
	consumeIngredients() {
		recipe.consumeIngredients();
	}

	afterTransition() {
		recipe.produceResult();
	}
;
