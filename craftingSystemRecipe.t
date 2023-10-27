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
	recipeID = nil

	// What the recipe produces.  Probably a Thing class.
	result = nil

	// Optional location for the result to appear.  
	resultLocation = nil

	// The CraftingSystem we're part of.
	craftingSystem = nil

	// Ordered list of our steps.
	_recipeStep = perInstance(new Vector())

	// Called at preinit.
	initializeRecipe() {
		initializeRecipeCraftingSystem();
		compileRecipe();
	}

	// Add this recipe to its crafting system.
	initializeRecipeCraftingSystem() {
		if((location == nil) || !location.ofKind(CraftingSystem))
			return;
		location.addRecipe(self);
	}

	// Returns the "bottommost" ingredient list.
	getIngredientList() {
		local i;

		for(i = _recipeStep.length; i > 0; i--) {
			if(_recipeStep[i].ofKind(IngredientList))
				return(_recipeStep[i]);
		}

		return(nil);
	}

	// If an ingredient is added directly to the recipe, get the
	// "bottommost" ingredient list and add the ingredient to it.
	// If there is not ingredient list, create one, add it to the
	// recipe, and use it.
	addIngredient(obj) {
		local lst;

		if((obj == nil) || !obj.ofKind(Ingredient))
			return(nil);

		if((lst = getIngredientList()) == nil) {
			lst = new IngredientList();
			addRecipeStep(lst);
		}

		lst.addIngredient(obj);

		return(true);
	}

	// Add a recipe step to our list.
	addRecipeStep(obj) {
		if((obj == nil) || !obj.ofKind(RecipeStep))
			return;

		obj.recipe = self;

		_recipeStep.append(obj);
	}

	addRecipeState(obj) {
		obj.recipe = self;
		return(addState(obj));
	}

	removeRecipeState(obj) { return(removeState(obj)); }

	recipeAction() {}

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

	consumeIngredients() {
		_recipeStep.forEach(function(o) {
			if(!o.ofKind(IngredientList))
				return;
			o.consumeIngredients();
		});
	}
;
