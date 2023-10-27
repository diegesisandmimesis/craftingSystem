#charset "us-ascii"
//
// craftingSystemRecipe.t
//
#include <adv3.h>
#include <en_us.h>

#include "craftingSystem.h"

// Recipe is a special kind of state machine.
class Recipe: StateMachine, CraftingSystemObject
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

	// List of ingredients
	_ingredientList = nil

	// Returns the ID of the numbered recipe step.
	getStepID(idx) {
		// Check that the index is valid.
		if((idx < 1) || (idx > _recipeSteps.length))
			return(nil);

		// If step has a declared ID, use it.
		if(_recipeSteps[idx].id != nil)
			return(_recipeSteps[idx].id);

		return(_indexToStepID(idx));
	}

	// Converts an index (number) into a step ID.
	// This is simple, but we make it its own method in case we
	// need to change it.
	_indexToStepID(idx) { return('step <<toString(idx)>>'); }

	// Utility methods for getting the first and last step IDs.
	getFirstStepID() { return(getStepID(1)); }
	getLastStepID() { return(getStepID(_recipeSteps.length)); }

	// Return the given numbered step object.
	getStep(idx) {
		if((idx < 1) || (idx > _recipeSteps.length))
			return(nil);
		return(_recipeSteps[idx]);
	}

	// Add an ingredient to the list, creating a new list if one
	// doesn't already exist.
	addIngredient(obj) {
		if((obj == nil) || !obj.ofKind(Ingredient))
			return(nil);

		if(_ingredientList == nil)
			_ingredientList = new Vector();

		_ingredientList.append(obj);

		return(true);
	}

	// Called at preinit.
	initializeRecipe() {
		initializeRecipeLocation();
		initializeRecipeStates();
	}

	// Add this recipe to its crafting system.
	initializeRecipeLocation() {
		if((location == nil) || !location.ofKind(CraftingSystem))
			return;
		location.addRecipe(self);
		craftingSystem = location;
	}

	// Create state machine states for each recipe step.
	initializeRecipeStates() {
		local i;

		canonicalizeRecipeSteps();

		_debug('initializing recipe <q><<id>></q>:
			<<toString(_recipeSteps.length)>> steps');

		stateID = getStepID(1);
		
		for(i = 1; i <= _recipeSteps.length; i++) {
			if(addState(createRecipeState(i)) != true)
				_debug('failed to add state');
		}
	}

	// If this recipe has an ingredient list, add a recipe step that
	// checks if all the ingredients are where they're supposed to be.
	canonicalizeRecipeSteps() {
		local obj;

		if(_ingredientList == nil)
			return;

		obj = new RecipeStepIngredientList();
		_recipeSteps.insertAt(1, obj);
	}

	// Returns a new RecipeState instance for the given numbered step.
	_createRecipeState(idx) {
		local r;

		// Create the instance
		r = new RecipeState();
		r.id = getStepID(idx);
		r.recipe = self;

		r._initFlag = true;

		return(r);
	}

	// Returns a Transition instance for the transition between the
	// given numbered recipe step and whichever step comes after it.
	_createTransition(idx, reverse?) {
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
			if(reverse == true)
				nextIdx = idx - 1;
			else
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

		return(r);
	}

	// Creates a Trigger instance for the conditions specified in the
	// numbered recipe step.
	_createRule(idx) {
		local step;

		// Get the step instance.  It holds the configuration data.
		if((step = getStep(idx)) == nil)
			return(nil);

		// Create the trigger and set its properties.
		return(step.createRule());
	}

	// Create and set up a new RecipeState instance for handling
	// the step number given by the argument.
	createRecipeState(idx) {
		local step;

		step = getStep(idx);
		if(step.ofKind(RecipeStepIngredientList))
			return(createRecipeStateIngredients(idx));
		else
			return(createRecipeStateNormal(idx));
	}

	createRecipeStateIngredients(idx) {
		local book, i, rs, step;

		if((rs = _createRecipeState(idx)) == nil) {
			_error('failed to create state for recipe
				ingredients <<toString(idx)>>');
			return(nil);
		}

		_debug('adding recipe step <<toString(idx)>>:
			<<toString(rs.id)>>');

		// Create the Transition instance.
		if((book = _createTransition(idx)) == nil) {
			_error('failed to create forward transition for recipe
				step <<toString(idx)>>');
			return(nil);
		}

		step = getStep(idx);

		_debug('Adding <<toString(_ingredientList.length)>> ingredient
			rules.');
		for(i = 1; i <= _ingredientList.length; i++) {
			if((rule = step.createRule(self, step,
				_ingredientList[i])) == nil) {
				_error('failed to create rule for
					ingredient <<toString(i)>>');
				
			}
			book.addRule(rule);
		}

		_debug('\tforward = <q><<book.toState>></q>');

		rs.addRulebook(book);

/*
		// Create the "reverse" transition.
		if((book = _createTransition(idx, true)) == nil) {
			_error('failed to create reverse transition for recipe
				step <<toString(idx)>>');
			return(nil);
		}

		_debug('\treverse = <q><<book.toState>></q>');

		//book.addRule(rule);
		rs.addRulebook(book);
*/

		return(rs);
	}

	createRecipeStateNormal(idx) {
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

		// Create the Rule/Trigger instance.
		if((rule = _createRule(idx)) == nil) {
			_error('failed to create rule for recipe
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

		recipeAction();
	}

	_produceSingleResult(cls, loc) {
		local obj;

		if(cls == nil)
			return;
		
		obj = cls.createInstance();
		obj.moveInto(loc);
	}

	listRecipeSteps() {}

	recipeAction() {}
;
