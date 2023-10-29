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
	// A stack used for holding the un-added State instances during
	// "compilation".
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

		// Make sure all the steps are set up.
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

		return(true);
	}

	// We go through the recipe steps and make sure they all have
	// everything we're going to need defined on them.
	canonicalizeRecipe() {
		local i;

		for(i = 1; i <= _recipeStep.length(); i++) {
			_canonicalizeRecipeStep(i, _recipeStep[i]);
		}
	}

	// Make sure everything is defined on the given recipe step.
	_canonicalizeRecipeStep(i, step) {
		// Make sure the step has an ID.
		if(step.stepID == nil)
			step.stepID = 'step <<toString(i)>>';

		// Remember our index.
		step.recipeIdx = i;
	}

	// Generate all of the states we'll need for the recipe.
	// This involves creating a default state and then figuring out
	// which recipe steps need new states.
	_createRecipeStates() {
		local i, n;

		// Create the default state.
		_stateStack.append(_createRecipeState('default'));
		stateID = 'default';

		// Compute the number of additional recipe states.
		n = _recipeStep.countWhich({o: o.ofKind(RecipeStepWithState)});

		// Create all but one of the recipe states; the last state
		// isn't a new state, but returning to the initial state.
		// Note:  the i < n condition isn't a typo, it should NOT
		// be i <= n.
		for(i = 1; i < n; i++) {
			_stateStack.append(_createRecipeState(
				'state <<toString(i)>>'));
		}
	}

	// Returns the State instance with the given index in the state stack.
	// The gimmick here is that we return the first state if we request
	// an index off the end of the stack.  This is because each state
	// understands a "forward" transition as being to the state with an
	// index greater that its own, and the "forward" transition from
	// the last state in a recipe finishes the recipe, resetting the
	// state.
	_getStateByIndex(idx) {
		return(_stateStack[(idx > _stateStack.length) ? 1 : idx]);
	}

	
	// Set up all the recipe states, including all their transitions
	// and rules.  This is the main "meat" of the "compilation"
	// process.
	// Called by compileRecipe()
	createRecipeStates() {
		local i, n, lastState, fromState, toState;

		// Figure out how many states we'll need and create
		// that many instances, putting them in the stack.
		_createRecipeStates();

		// Figure out which state is the last one.  We handle
		// it slightly differently to make sure all of the
		// recipe completion actions happen.
		lastState = _stateStack[_stateStack.length];

		// Pointers to the current "from" and "to" states.
		// We start out "from" the starting state, and "to"
		// nothing in particular.
		fromState = _stateStack[1];
		toState = nil;

		// Counter for our current place in the stack.
		n = 0;

		// Now we walk through our list of recipe steps, creating
		// transitions as we go.
		for(i = 1; i <= _recipeStep.length; i++) {
			// If the step we're currently looking at creates
			// a state, we update the "from" and "to" pointers
			// so the "from" state is the current state in
			// the stack and the "to" state is the next one
			// after it (or the first state, if the "from"
			// state is the last one in the stack).
			if(_recipeStep[i].ofKind(RecipeStepWithState)) {
				n += 1;
				fromState = _getStateByIndex(n);
				toState = _getStateByIndex(n + 1);
			}

			// Create the transition(s) for this recipe step
			// from the current state and to the next state.
			// Third arg is boolean true if the "from" state
			// is the last state.
			_recipeStep[i].createRecipeTransitions(fromState,
				toState, (fromState == lastState));
		}
	}

	// Create a state with the given ID.  Second arg is the class to use,
	// other than the default RecipeState.
	_createRecipeState(id, cls?) {
		local state;

		state = ((cls != nil) ? cls : RecipeState).createInstance();
		state.id = id;
		state.recipe = self;

		return(state);
	}
;
