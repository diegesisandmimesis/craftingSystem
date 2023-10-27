#charset "us-ascii"
//
// craftingSystemRecipeCompiler.t
//
//	The logic for building state machine states and transitions for
//	a recipe.
//
#include <adv3.h>
#include <en_us.h>

#include "craftingSystem.h"

modify Recipe
	// Step ID utility methods.
	// Get the step ID for the step with the given index.
	getStepID(idx) {
		if((idx < 1) || (idx > _recipeStep.length))
			return(nil);
		return(_recipeStep[idx].stepID);
	}

	// Get the ID of the first step.
	getFirstStepID() { return(getStepID(1)); }

	// Get the ID of the last step.
	getLastStepID() { return(getStepID(_recipeStep.length)); }

	// "Compile" the recipe into a state machine.
	compileRecipe() {
		local i, s;

		for(i = 1; i <= _recipeStep.length; i++) {
			// Make sure everything's defined on this step.
			_canonicalizeRecipeStep(i, _recipeStep[i]);
		}

		stateID = getFirstStepID();

		_debug('compiling <<toString(_recipeStep.length)>> steps');
		for(i = 1; i <= _recipeStep.length; i++) {
			// Create the State instance for this recipe step.
			if((s = _createRecipeState(i, _recipeStep[i])) == nil) {
				_error('failed to create state for recipe
					step <<toString(i)>>');
				return(nil);
			}

			// Add the state to the recipe's state machine.
			if(addRecipeState(s) != true) {
				_error('failed to add state for recipe
					step <<toString(i)>>');
				return(nil);
			}
		}

		return(true);
	}

	// Make sure everything is defined on the given recipe step.
	// Mostly just for making sure every step has a stepID defined.
	_canonicalizeRecipeStep(i, step) {
		if(step.stepID == nil)
			step.stepID = 'step <<toString(i)>>';
	}

	// Create the state for for given step.
	_createRecipeState(idx, step) {
		local r;

		r = new RecipeState();

		r.id = step.stepID;
		r.recipe = self;

		// Create all the state's transitions.
		if(step.createRecipeTransition(idx, r) != true) {
			_error('failed to create transitions for recipe
				step <<toString(idx)>>');
			return(nil);
		}

		return(r);
	}
;
