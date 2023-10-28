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
	_stateStack = perInstance(new Vector())

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
		local i;

		canonicalizeRecipe();

		stateID = getFirstStepID();

		createRecipeStates();

		for(i = 1; i <= _stateStack.length; i++) {
			if(addRecipeState(_stateStack[i]) != true) {
				_error('failed to add state for recipe step
					<q><<toString(getStepID(i))>></q>');
				return(nil);
			}
		}

/*
		_debug('compiling <<toString(_recipeStep.length)>> steps');
		for(i = 1; i <= _recipeStep.length; i++) {
			// Create the State instance for this recipe step.
			if((s = _createRecipeState(_recipeStep[i])) == nil) {
				_error('failed to create state for recipe step
					<q><<toString(_recipeStep[i]
					.stepID)>></q>');
				return(nil);
			}

			// Add the state to the recipe's state machine.
			if(addRecipeState(s) != true) {
				_error('failed to add state for recipe step
					<q><<toString(_recipeStep[i]
					.stepID)>></q>');
				return(nil);
			}
		}

		for(i = 1; i <= _recipeStep.length; i++) {
			_recipeStep[i].recipeStepSetup();
		}

*/
		return(true);
	}

	canonicalizeRecipe() {
		local i;

		for(i = 1; i <= _recipeStep.length(); i++) {
			// Make sure everything's defined on this step.
			_canonicalizeRecipeStep(i, _recipeStep[i]);
		}
	}

	// Make sure everything is defined on the given recipe step.
	// Mostly just for making sure every step has a stepID defined.
	_canonicalizeRecipeStep(i, step) {
		if(step.stepID == nil)
			step.stepID = 'step <<toString(i)>>';
		step.recipeIdx = i;
	}

	_getTopState() { return(_stateStack[_stateStack.length]); }

	_createRecipeStates() {
		local i, n;

		// Create the default state.
		_stateStack.append(_createRecipeState('default'));
		stateID = 'default';

		// Number of addition recipe states.
		n = _recipeStep.countWhich({o: o.ofKind(RecipeStepWithState)});

		// Create all but one of the recipe states; the last state
		// isn't a new state, but returning to the initial state.
		for(i = 1; i < n; i++) {
			_stateStack.append(_createRecipeState(
				'state <<toString(i)>>'));
		}
	}

	_getStateByIndex(idx) {
		return(_stateStack[(idx > _stateStack.length) ? 1 : idx]);
	}

	createRecipeStates() {
		local i, n, o, lastState, fromState, toState;

		_createRecipeStates();

		lastState = _stateStack[_stateStack.length];

		fromState = nil;
		toState = nil;

		n = 0;
		for(i = 1; i <= _recipeStep.length; i++) {
			o = _recipeStep[i];
			if(o.ofKind(RecipeStepWithState)) {
				n += 1;
				fromState = _getStateByIndex(i);
				toState = _getStateByIndex(n + 1);
			}
if(fromState == lastState) {
	aioSay('\ncreating final transition\n ');
	aioSay('\n<<toString(fromState.id)>> to <<toString(toState.id)>>\n ');
}
			o.createRecipeTransitions(fromState, toState,
				(fromState == lastState));
		}
	}

	_createRecipeState(id, cls?) {
		local state;

		if(cls == nil)
			cls = RecipeState;
		state = cls.createInstance();
		//state = ((cls != nil) ? cls : RecipeState).createInstance();
		state.id = id;
		state.recipe = self;

		return(state);
	}

/*
	// Create the state for for given step.
	_createRecipeState(step) {
		local r;

		r = new RecipeState();

		r.id = step.stepID;
		r.recipe = self;

		// Create all the state's transitions.
		if(step.createRecipeTransition(r) != true) {
			_error('failed to create transitions for recipe
				<<toString(step.stepID)>>');
			return(nil);
		}

		return(r);
	}
*/
;
