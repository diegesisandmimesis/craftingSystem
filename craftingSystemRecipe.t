#charset "us-ascii"
//
// craftingSystemRecipe.t
//
//	The Recipe class.  It's a special kind of state machine that's
//	mostly linear and produces something in the final state.
//
#include <adv3.h>
#include <en_us.h>

#include "craftingSystem.h"

// Recipe is a special kind of state machine.
class Recipe: StateMachine, CraftingSystemObject
	syslogID = 'Recipe'
	syslogFlag = 'Recipe'

	// Recipe ID.
	recipeID = nil

	// What the recipe produces.  Probably a Thing class.
	result = nil

	// Optional location for the result to appear.  This will ALSO
	// be used as the default "mixing" location for ingredients, unless
	// a different location is specified in the ingredient list or on
	// the individual ingredients.
	resultLocation = nil

	// Set by IngredientAction when changing the resultLocation
	_resultLocationFlag = nil

	// The CraftingSystem we're part of.
	craftingSystem = nil

	// If defined, this recipe is only active in the given location.
	craftingLocation = nil

	// Ordered list of the recipe steps.
	_recipeStep = perInstance(new Vector())

	// RecipeShortcut instance for this recipe, if defined.
	_recipeShortcut = nil

	// Called at preinit.
	initializeRecipe() {
		// Add the recipe to the crafting system.
		initializeRecipeCraftingSystem();

		// "Compile" the recipe.
		compileRecipe();
	}

	// Add this recipe to its crafting system.
	initializeRecipeCraftingSystem() {
		if((location == nil) || !location.ofKind(CraftingSystem))
			return;
		location.addRecipe(self);
	}

	addRecipeShortcut(obj) {
		if((obj == nil) || !obj.ofKind(RecipeShortcut))
			return;

		_recipeShortcut = obj;
	}

	clearResultLocationFlag() {
		if(_resultLocationFlag == nil)
			return;
		_resultLocationFlag = nil;
		resultLocation = nil;
	}

	setLocationFlag(loc) {
		resultLocation = loc;
		_resultLocationFlag = true;
	}

	// Returns the "bottommost" ingredient list.
	// Ingredients can be added directly to the recipe (instead of
	// explicitly to an ingredient list).  If that happens, this is
	// how we figure out what ingredient list to use.
	// This is intended to be used during preinit, as the _recipeStep
	// list is being constructed (and so the last ingredient list
	// in _recipeStep might be changing).
	getIngredientList() {
		local i;

		// Walk backwards through the recipe steps, returning
		// the first (last) ingredient list we find.
		for(i = _recipeStep.length; i > 0; i--) {
			if(_recipeStep[i].ofKind(IngredientList))
				return(_recipeStep[i]);
		}

		// Didn't find anything.
		return(nil);
	}

	// If an ingredient is added directly to the recipe, get the
	// "bottommost" ingredient list and add the ingredient to it.
	// If there is not ingredient list, create one, add it to the
	// recipe, and use it.
	addIngredient(obj) {
		local lst;

		// Make sure the arg is an Ingredient.
		if((obj == nil) || !obj.ofKind(Ingredient))
			return(nil);

		// Get the most recently added ingredient list.  If
		// none exists, create a new ingredient list and add it
		// to the recipe steps.
		if((lst = getIngredientList()) == nil) {
			lst = new IngredientList();
			addRecipeStep(lst);
		}

		// Add the ingredient to the list.
		lst.addIngredient(obj);

		return(true);
	}

	// Add a recipe step to our list.
	addRecipeStep(obj) {
		if((obj == nil) || !obj.ofKind(RecipeStep))
			return;

		// Remember what recipe the step is a part of.
		obj.recipe = self;

		_recipeStep.append(obj);
	}

	// Add a recipe state.
	addRecipeState(obj) {
		if((obj == nil) || !obj.ofKind(RecipeState))
			return(nil);

		// Remember what recipe the state is a part of.
		obj.recipe = self;

		return(addState(obj));
	}

	// Remove the given state from the recipe.
	removeRecipeState(obj) { return(removeState(obj)); }

	// Stub method.  Called when the recipe is completed.
	recipeAction() {}

	// Produce whatever the recipe produces.
	// Called after the final recipe transition.
	produceResult() {
		local loc;

		// If we have no result defined, nothing to do.
		if(result == nil)
			return;

		// If we have a location for the result, use it.  Otherwise
		// we punt by assuming it goes into whatever location the
		// gActor is in.
		if(resultLocation)
			loc = resultLocation;
		else
			loc = gActor.location;

		// Figure out if we have one result or many.
		if(result.ofKind(List)) {
			result.forEach(function(o) {
				_produceSingleResult(o, loc);
			});
		} else {
			_produceSingleResult(result, loc);
		}

		// If we have further stuff to do on recipe completion, we
		// do it now.
		recipeAction();
	}

	// Produce a single recipe result.
	_produceSingleResult(cls, loc) {
		local obj;

		if(cls == nil)
			return;

		obj = cls.createInstance();
		obj.moveInto(loc);
	}

	// Consume all the ingredients used in the recipe, by telling
	// each recipe step to consume its associated ingredients.
	consumeIngredients() {
		_recipeStep.forEach(function(o) {
			if(!o.ofKind(IngredientList))
				return;
			o.consumeIngredients();
		});
	}

	validateStateTransition() {
		// If the state ID is changing, always okay.
		if(_nextStateID != stateID)
			return(true);

		// If the state ID is NOT changing, it's only okay
		// if we only have one state.
		return(_stateStack.length == 1);
	}

	checkRecipeLocation() {
		if(craftingLocation == nil)
			return(true);
		if(gActor.getOutermostRoom() != craftingLocation)
			return(nil);
		return(true);
	}
;
