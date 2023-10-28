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

	recipeTransition = nil

	recipeRule = nil

	recipeIdx = nil

	initializeRecipeStep() {
		if((location == nil) || !location.ofKind(Recipe))
			return;
		location.addRecipeStep(self);
	}

	createRecipeTransition(state) { return(nil); }

	_createRecipeTransitionByClass(cls, state, toIdx) {
		local r;

		r = cls.createInstance();
		r.recipeStep = self;
		r.recipe = recipe;
		r.ruleUser = state;
		if(toIdx)
			r.toState = recipe.getStepID(toIdx);

		recipeTransition = r;

		return(r);
	}

	_createRecipeTransition(state, reverse?) {
		if(recipeIdx == recipe._recipeStep.length) {
			return(_createRecipeTransitionByClass(RecipeEnd,
				state, 1));
		}

		return(_createRecipeTransitionByClass(RecipeTransition,
			state,
			((reverse == true) ? (recipeIdx - 1)
				: (recipeIdx + 1))));
	}

	_createRecipeNoTransition(state, reverse?) {
		return(_createRecipeTransitionByClass(RecipeNoTransition,
			state, nil));
	}

	recipeStepSetup() {}

	recipeAction() {}
;

class RecipeAction: RecipeStep, Tuple
	syslogID = 'RecipeAction'

	createRecipeTransition(state) {
		local book, rule;

		if((book = _createRecipeTransition(state)) == nil) {
			_error('failed to create transition');
			return(nil);
		}

		if((rule = createRule()) == nil) {
			_error('failed to create rule');
			return(nil);
		}

		book.addRule(rule);
		state.addRulebook(book);

		return(true);
	}

	createRule() {
		local r;

		r = new Trigger();
		r.srcObject = srcObject;
		r.dstObject = dstObject;
		r.action = action;

		recipeRule = r;

		return(r);
	}
;

class RecipeBlank: RecipeAction
	syslogID = 'RecipeBlank'

	createRecipeTransition(state) {
		local book, rule;

		if((book = _createRecipeNoTransition(state)) == nil) {
			_error('failed to create transition');
			return(nil);
		}

		if((rule = createRule()) == nil) {
			_error('failed to create rule');
			return(nil);
		}

		book.addRule(rule);
		state.addRulebook(book);

		return(true);
	}
;
