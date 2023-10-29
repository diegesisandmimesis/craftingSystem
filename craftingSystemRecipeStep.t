#charset "us-ascii"
//
// craftingSystemRecipeStep.t
//
//	RecipeStep classes.  These are used for declaring recipes.
//
#include <adv3.h>
#include <en_us.h>

#include "craftingSystem.h"

// Base RecipeStep class.  Agnostic as to what kind of step it is, mostly
// a holder for generic recipe methods.
class RecipeStep: CraftingSystemObject
	syslogID = 'RecipeStep'
	syslogFlag = 'RecipeStep'

	// Unique(ish) ID for this recipe step.
	stepID = nil

	// The recipe we're part of.
	recipe = nil

	// This step's index in the recipe.
	recipeIdx = nil

	// The Rule instance we created, if any.
	recipeRule = nil

	// Called at preinit.  Add ourselves to our Recipe.
	initializeRecipeStep() {
		if((location == nil) || !location.ofKind(Recipe))
			return;
		location.addRecipeStep(self);
	}

	// Entry point for the recipe "compiler".  Subclasses will use
	// this to create whatever transitions they need.
	createRecipeTransitions(fromState, toState, last?) { return(nil); }

	// Utility method.  Creates a Transition of the given class,
	// from and to the given states.
	_createRecipeTransitionByClass(cls, fromState, toState) {
		local r;

		// Create the instance.
		r = cls.createInstance();

		// Remember what step created us and what recipe we're part of.
		r.recipeStep = self;
		r.recipe = recipe;

		// Record what states we transition between.
		r.ruleUser = fromState;
		r.toState = ((toState != nil) ? toState.id : nil);

		//recipeTransition = r;

		return(r);
	}

	// Generic transition creation method.  This takes care of
	// using the special RecipeEnd class if necessary.
	_createRecipeTransition(fromState, toState, last?) {
		if(last == true) {
			return(_createRecipeTransitionByClass(RecipeEnd,
				fromState, toState));
		}

		return(_createRecipeTransitionByClass(RecipeTransition,
			fromState, toState));
	}

	// Create a "no transition" transition on the given state.
	_createRecipeNoTransition(fromState) {
		return(_createRecipeTransitionByClass(RecipeNoTransition,
			fromState, nil));
	}

	// Wrapper method.  For the default single-transition generator
	// method.
	createSingleRecipeTransition(fromState, toState, last) {
		return(_createRecipeTransition(fromState, toState, last));
	}

	// Stub method.
	recipeAction() {}
;

// Class for recipe steps that create new states.  Used as a mixin.
class RecipeStepWithState: RecipeStep syslogID = 'RecipeStepWithState';

// Class for recipe steps that define triggers.
// Basically this is for the methods common to RecipeAction and RecipeNoAction.
class RecipeStepWithTrigger: RecipeStep, Tuple
	syslogID = 'RecipeAction'

	// Create a single transition, from one state to the other.
	// Note that toState might be nil.
	createRecipeTransitions(fromState, toState, last?) {
		local book, rule;

		// Create the transition or die trying.
		if((book = createSingleRecipeTransition(fromState, toState,
			last)) == nil) {
			_error('failed to create transition');
			return(nil);
		}

		// Create the rule for the transition.
		if((rule = createRule()) == nil) {
			_error('failed to create rule');
			return(nil);
		}

		// Add the rule to the transition then add the transition to
		// the state.
		book.addRule(rule);
		fromState.addRulebook(book);

		return(true);
	}

	// Create a trigger.
	createRule() {
		local r;

		r = new Trigger();
		r.srcObject = srcObject;
		r.dstObject = dstObject;
		r.action = action;

		// Remember the rule we're part of.
		recipeRule = r;

		return(r);
	}
;

// General recipe action.  It creates a new state and has a trigger to
// switch to it.
class RecipeAction: RecipeStepWithState, RecipeStepWithTrigger;

// "No action" action trigger.  This is primarily for informational message,
// like reporting that turning a toaster on with nothing in it does nothing.
// This doesn't change the state.
class RecipeNoAction: RecipeStepWithTrigger
	syslogID = 'RecipeNoAction'

	// Our single transition generator returns a "no transition" transition.
	createSingleRecipeTransition(fromState, toState, last?) {
		return(_createRecipeNoTransition(fromState));
	}
/*
	createRecipeTransition(fromState, toState) {
		local book, rule;

		if((book = _createRecipeNoTransition(fromState)) == nil) {
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
*/
;
