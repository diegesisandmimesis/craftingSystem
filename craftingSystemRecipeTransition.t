#charset "us-ascii"
//
// craftingSystemRecipeTransition.t
//
#include <adv3.h>
#include <en_us.h>

#include "craftingSystem.h"

// RecipeTransition is a StateMachine Transition for completing a recipe step.
class RecipeTransition: Transition
	recipe = nil		// the recipe we're part of
	recipeStepIdx = nil	// the recipe step we represent

	reversible = nil

	isReversible() { return((reversible == true) ? true : nil); }

	recipeAction() {
		local step;

		if((step = getStep()) == nil)
			return;

		step.recipeAction();
	}

	getStep() {
		// We have to know our recipe.
		if(recipe == nil)
			return(nil);

		return(recipe.getStep(recipeStepIdx));
	}

	transitionAction() {
		consumeIngredients();

		recipeAction();
	}

	consumeIngredients() {
		local step;

		// Get the step.
		if((step = getStep()) == nil)
			return;

		if(step.dstObject != nil) {
			if(step.srcObject != nil)
				consumeIngredient(gIobj);
			consumeIngredient(gDobj);
		}
	}

	consumeIngredient(obj) {
		if((obj == nil) || !obj.ofKind(CraftingIngredient))
			return(nil);
		obj.moveInto(nil);
		return(true);
	}
;

class RecipeTransitionReversible: RecipeTransition reversible = true;

// RecipeEnd is for handling the last state transition in the recipe.
class RecipeEnd: RecipeTransition
	transitionAction() {
		consumeIngredients();

		if(recipe != nil)
			recipe.produceResult();

		recipeAction();
	}
;
