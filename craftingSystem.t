#charset "us-ascii"
//
// craftingSystem.t
//
#include <adv3.h>
#include <en_us.h>

#include "craftingSystem.h"

// Module ID for the library
craftingSystemModuleID: ModuleID {
        name = 'Crafting System Library'
        byline = 'Diegesis & Mimesis'
        version = '1.0'
        listingOrder = 99
}

class CraftingSystemObject: RuleEngineObject
	syslogID = 'CraftingSystem'
	syslogFlag = 'CraftingSystem'
;

// Ownership-agnostic preinit.  Goes through all the various bits of recipes
// and makes sure they're inintialized, but we don't keep track of anything
// in this singleton.
craftingSystemPreinit: PreinitObject
	execute() {
		initializeIngredients();
		initializeRecipeSteps();
		initializeRecipes();
	}

	initializeIngredients() {
		forEachInstance(Ingredient, function(o) {
			o.initializeIngredient();
		});
	}

	initializeRecipeSteps() {
		forEachInstance(RecipeStep, function(o) {
			o.initializeRecipeStep();
		});
	}

	initializeRecipes() {
		forEachInstance(Recipe, function(o) {
			o.initializeRecipe();
		});
	}
;

// Base class for crafting systems.
class CraftingSystem: CraftingSystemObject
	syslogID = 'CraftingSystem'

	_recipeList = perInstance(new Vector())

	addRecipe(obj) {
		if((obj == nil) || !obj.ofKind(Recipe))
			return(nil);
		obj.craftingSystem = self;
		_recipeList.append(obj);
		return(true);
	}

	removeRecipe(obj) {
		if(_recipeList.indexOf(obj) == nil)
			return(nil);
		_recipeList.removeElement(obj);
		return(true);
	}
;
