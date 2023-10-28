#charset "us-ascii"
//
// craftingSystemRecipeStep.t
//
#include <adv3.h>
#include <en_us.h>

#include "craftingSystem.h"

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

	createRecipeTransitions(fromState, toState, last?) { return(nil); }

	_createRecipeTransitionByClass(cls, fromState, toState) {
		local r;

		r = cls.createInstance();
		r.recipeStep = self;
		r.recipe = recipe;
		r.ruleUser = fromState;
		r.toState = ((toState != nil) ? toState.id : nil);

		recipeTransition = r;

		return(r);
	}

	_createRecipeTransition(fromState, toState, last?) {
		if(last == true) {
			return(_createRecipeTransitionByClass(RecipeEnd,
				fromState, toState));
		}

		return(_createRecipeTransitionByClass(RecipeTransition,
			fromState, toState));
	}

	_createRecipeNoTransition(fromState) {
		return(_createRecipeTransitionByClass(RecipeNoTransition,
			fromState, nil));
	}

	recipeStepSetup() {}

	recipeAction() {}
;

class RecipeStepWithState: RecipeStep
	syslogID = 'RecipeStepWithState'

;

class RecipeAction: RecipeStepWithState, Tuple
	syslogID = 'RecipeAction'

	createRecipeTransitions(fromState, toState, last?) {
		local book, rule;

		if((book = _createRecipeTransition(fromState, toState, last))
			== nil) {
			_error('failed to create transition');
			return(nil);
		}

		if((rule = createRule()) == nil) {
			_error('failed to create rule');
			return(nil);
		}

		book.addRule(rule);
		fromState.addRulebook(book);

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

/*
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
*/
