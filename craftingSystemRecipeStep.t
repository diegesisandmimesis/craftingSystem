#charset "us-ascii"
//
// craftingSystemRecipeStep.t
//
#include <adv3.h>
#include <en_us.h>

#include "craftingSystem.h"

// Recipe is a special kind of state machine.
class RecipeStep: CraftingSystemObject
	syslogID = 'RecipeStep'
	syslogFlag = 'RecipeStep'

	// Unique(ish) ID for this recipe step.
	stepID = nil

	// The recipe we're part of.
	recipe = nil

	recipeStep = nil

	initializeRecipeStep() {
		if((location == nil) || !location.ofKind(Recipe))
			return;
		location.addRecipeStep(self);
	}

	createRecipeTransition(idx, state) { return(nil); }

	_createRecipeTransition(idx, state, reverse?) {
		local nextIdx, r;

		if(idx == recipe._recipeStep.length) {
			nextIdx = 1;
			r = new RecipeEnd();
		} else {
			nextIdx = ((reverse == true) ? (idx - 1) : (idx + 1));
			r = new RecipeTransition();
		}


		r.toState = recipe.getStepID(nextIdx);
		r.recipeStep = self;
		r.recipe = recipe;
		r.ruleUser = state;

		return(r);
	}

	recipeAction() {}
;

class RecipeAction: RecipeStep, Tuple
	syslogID = 'RecipeAction'

	createRecipeTransition(idx, state) {
		local book, rule;

		if((book = _createRecipeTransition(idx, state)) == nil) {
			_error('failed to create transition');
			return(nil);
		}

		if((rule = createRule(idx)) == nil) {
			_error('failed to create rule');
			return(nil);
		}

		book.addRule(rule);
		state.addRulebook(book);

		return(true);
	}

	createRule(idx) {
		local r;

		r = new Trigger();
		r.srcObject = srcObject;
		r.dstObject = dstObject;
		r.action = action;

		return(r);
	}
;
