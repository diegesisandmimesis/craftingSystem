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

	id = nil

	result = nil

	craftingSystem = nil

	_recipeSteps = perInstance(new Vector())
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
			if(_stateMachine.addState(newRecipeStep(i)) != true)
				_debug('failed to add state');
		}
	}

	initializeRecipeLocation() {
		if((location == nil) || !location.ofKind(CraftingSystem))
			return;
		location.addRecipe(self);
		craftingSystem = location;
	}

	newRecipeStep(idx) {
		local book, nextIdx, rule, step;

		if((step = getStep(idx)) == nil)
			return(nil);

		state = new State();
		state.id = getStepID(idx);

		_debug('adding recipe step <<toString(idx)>>:
			<<toString(state.id)>>');

		if(idx == _recipeSteps.length) {
			nextIdx = 1;
			book = new RecipeEnd();
		} else {
			nextIdx = idx + 1;
			book = new Transition();
		}

		book.toState = getStepID(nextIdx);
		_debug('\ttoState = <q><<book.toState>></q>');

		rule = new Trigger();
		rule.srcObject = step.srcObject;
		rule.dstObject = step.dstObject;
		rule.action = step.action;

		book.addRule(rule);

		state.addRulebook(book);

		return(state);
	}

	addRecipeStep(obj) {
		if((obj == nil) || !obj.ofKind(RecipeStep))
			return;
		_recipeSteps.append(obj);
	}

	listRecipeSteps() {}
;

class RecipeStep: CraftingSystemObject
	syslogID = 'RecipeStep'

	srcObject = nil
	dstObject = nil
	action = nil

	recipe = nil

	initializeRecipeStep() {
		if((location == nil) || !location.ofKind(Recipe))
			return;
		location.addRecipeStep(self);
		recipe = location;
	}

	listRecipeStep() {}
	printStateMachine() {}
;

class RecipeEnd: Transition
	afterTransition() {
		"Recipe complete. ";
	}
;
