#charset "us-ascii"
//
// craftingSystemRecipeStep.t
//
#include <adv3.h>
#include <en_us.h>

#include "craftingSystem.h"

class RecipeStep: CraftingSystemObject
	syslogID = 'RecipeStep'

	reversible = true

	rule = nil

	initializeRecipeStep() {
		if((location == nil) || !location.ofKind(Recipe))
			return;

		location.addRecipeStep(self);
		recipe = location;
	}

	createRule() {
		local obj;

		if(!propDefined(&rule) || (propType(&rule) == TypeNil))
			return(nil);
		
		obj = new RecipeRule();
		obj.recipeStep = self;

		return(obj);
	}

	matchRule(data?) { return(rule()); }

	recipeAction() {}

        isReversible() { return((reversible == true) ? true : nil); }

        listRecipeStep() {}
        printStateMachine() {}
;

/*
class RecipeStepRevert: RecipeStep
	matchRule(data?) { return(!rule()); }
;
*/

class RecipeStepIngredientList: RecipeStep
	createRule(recipe, step, ingr) {
		local i, loc, rule;

		// Make sure the step is a Step.
		if((step == nil) || !step.ofKind(RecipeStep)) {
			_error('invalid recipe step');
			return(nil);
		}

		// Make sure the ingr is an Ingredient (or a list of them)
		if(ingr == nil) {
			_error('invalid ingredient:  nil');
			return(nil);
		}
		if(ingr.ofKind(Vector)) {
			for(i = 1; i <= ingr.length; i++) {
				if(!ingr[i].ofKind(Ingredient)) {
					_error('invalid ingredient: list');
					return(nil);
				}
			}
		} else {
			if(!ingr.ofKind(Ingredient)) {
				_error('invalid ingredient: object');
				return(nil);
			}
		}

		rule = new IngredientRule();
		rule.ingredient = ingr.ingredient;
		if(ingr.gear != nil) {
			loc = ingr.gear;
		} else {
			loc = recipe.result;
		}

		if(loc == nil) {
			_error('unable to determine ingredient rule location');
			return(nil);
		}

		if(!loc.ofKind(CraftingGear)) {
			_error('invalid ingredient rule location');
			return(nil);
		}

		rule.gear = loc;

		return(rule);
	}
;
