#charset "us-ascii"
//
// craftingSystemRecipe.t
//
#include <adv3.h>
#include <en_us.h>

#include "craftingSystem.h"

class Recipe: CraftingSystemObject
	syslogID = 'Recipe'
	syslogFlag = 'Recipe'

	// Recipe ID.
	id = nil

	// What the recipe produces.  Probably a Thing class.
	result = nil

	// Optional location for the result to appear.  
	resultLocation = nil

	// The CraftingSystem we're part of.
	craftingSystem = nil

	// Ordered list of our steps.
	_recipeSteps = perInstance(new Vector())

	// StateMachine used to track the recipe state.
	_stateMachine = perInstance(new StateMachine())

	getStepID(idx) {
		if((idx < 1) || (idx > _recipeSteps.length))
			return(nil);
		if(_recipeSteps[idx].id != nil)
			return(_recipeSteps[idx].id);
		return('step <<toString(idx)>>');
	}

	getFirstStepID() { return(getStepID(1)); }
	getLastStepID() { return(getStepID(_recipeSteps.length)); }

	getStep(idx) {
		if((idx < 1) || (idx > _recipeSteps.length))
			return(nil);
		return(_recipeSteps[idx]);
	}

	initializeRecipe() {
		initializeRecipeLocation();
		initializeRecipeStates();
	}

	initializeRecipeStates() {
		local i;

		_debug('initializing recipe <q><<id>></q>:
			<<toString(_recipeSteps.length)>> steps');

		stateID = getStepID(1);
		
		for(i = 1; i <= _recipeSteps.length; i++) {
			if(_stateMachine.addState(createRecipeState(i)) != true)
				_debug('failed to add state');
		}
	}

	initializeRecipeLocation() {
		if((location == nil) || !location.ofKind(CraftingSystem))
			return;
		location.addRecipe(self);
		craftingSystem = location;
	}

	// Returns a new RecipeState instance for the given numbered step.
	_createRecipeState(idx) {
		local r;

		// Create the instance
		r = new RecipeState();
		r.id = getStepID(idx);
		r.recipe = self;

		return(r);
	}

	// Returns a Transition instance for the transition between the
	// given numbered recipe step and whichever step comes after it.
	_createTransition(idx) {
		local nextIdx, r, step;

		// Check to see if we're creating the last step in the
		// recipe, which requires some special handling.
		if(idx == _recipeSteps.length) {
			// We reset the recipe by making the next step
			// of the last step the first step.
			nextIdx = 1;

			// We use a special class for finishing up recipes.
			r = new RecipeEnd();
		} else {
			// By default the next step is just the next
			// numbered step.
			nextIdx = idx + 1;

			if((step = getStep(idx)) == nil)
				return(nil);

			// See if we should use the generic or reversible
			// transition class.  This determines whether or
			// not ingredients are consumed immediately.
			if(step.isReversible()) {
				r = new RecipeTransitionReversible();
			} else {
				r = new RecipeTransition();
			}
		}

		// Remember our step number.
		r.recipeStepIdx = idx;

		// The ID for the state to transition to is whatever the
		// ID of the next step is.
		r.toState = getStepID(nextIdx);

		// Let the transition know which recipe it's part of.
		r.recipe = self;

		//step.setRecipeAction(r);
		//r.setMethod(&recipeAction, step.(&recipeAction));
		//r.(&recipeAction) = step.(&recipeAction);

		return(r);
	}

	// Creates a Trigger instance for the conditions specified in the
	// numbered recipe step.
	_createTrigger(idx) {
		local r, step;

		// Get the step instance.  It holds the configuration data.
		if((step = getStep(idx)) == nil)
			return(nil);

		// Create the trigger and set its properties.
		r = new Trigger(step.getConfig());
		//r.srcObject = step.srcObject;
		//r.dstObject = step.dstObject;
		//r.action = step.action;

		return(r);
	}

	// Create and set up a new RecipeState instance for handling
	// the step number given by the argument.
	createRecipeState(idx) {
		local book, rule, rs;

		// Create the State instance.
		if((rs = _createRecipeState(idx)) == nil) {
			_error('failed to create state for recipe
				step <<toString(idx)>>');
			return(nil);
		}

		_debug('adding recipe step <<toString(idx)>>:
			<<toString(rs.id)>>');

		// Create the Transition instance.
		if((book = _createTransition(idx)) == nil) {
			_error('failed to create transition for recipe
				step <<toString(idx)>>');
			return(nil);
		}

		_debug('\ttoState = <q><<book.toState>></q>');

		// Create the Trigger instance.
		if((rule = _createTrigger(idx)) == nil) {
			_error('failed to create trigger for recipe
				step <<toString(idx)>>');
			return(nil);
		}

		// Add the Trigger to the Transition and add the Transition
		// to the State.
		book.addRule(rule);
		rs.addRulebook(book);

		// Return the configured State instance.
		return(rs);
	}

	// Add a recipe step to our list.
	addRecipeStep(obj) {
		if((obj == nil) || !obj.ofKind(RecipeStep))
			return;
		_recipeSteps.append(obj);
	}

	// Called when a recipe is completed, we create whatever the
	// recipe produces.
	produceResult() {
		local loc;

		if(result == nil)
			return;
		
		if(resultLocation)
			loc = resultLocation;
		else
			loc = gActor.location;

		if(result.ofKind(List)) {
			result.forEach(function(o) {
				_produceSingleResult(o, loc);
			});
		} else {
			_produceSingleResult(result, loc);
		}
	}

	_produceSingleResult(cls, loc) {
		local obj;

		if(cls == nil)
			return;
		
		obj = cls.createInstance();
		obj.moveInto(loc);
	}

	listRecipeSteps() {}
;
