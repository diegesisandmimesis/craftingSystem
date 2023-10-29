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

// Generic crafting system object.  Mostly for logging.
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

	// Initialize all the ingredients.  These are the declarative
	// statements in recipes, not the in-game objects they refer to.
	initializeIngredients() {
		forEachInstance(Ingredient, function(o) {
			o.initializeIngredient();
		});
	}

	// Initialize the recipe steps.  These are the "operative" bits
	// of the recipe describing actions and transitions.
	initializeRecipeSteps() {
		forEachInstance(RecipeStep, function(o) {
			o.initializeRecipeStep();
		});
	}

	// Initialize the recipes themselves.  These are state machines
	// that track the progress of the recipe they represent.
	initializeRecipes() {
		forEachInstance(Recipe, function(o) {
			o.initializeRecipe();
		});
	}
;

// Base class for crafting systems.  These are collections of recipes.
class CraftingSystem: CraftingSystemObject
	syslogID = 'CraftingSystem'

	// A vector of all the recipes we take care of.
	_recipeList = perInstance(new Vector())

	// Add a recipe.
	addRecipe(obj) {
		// Make sure the arg is a Recipe.
		if((obj == nil) || !obj.ofKind(Recipe))
			return(nil);

		// Remember what crafting system the recipe belongs to.
		obj.craftingSystem = self;

		// Add it.
		_recipeList.append(obj);

		return(true);
	}

	// Remove a recipe.
	removeRecipe(obj) {
		// Make sure its in the list.
		if(_recipeList.indexOf(obj) == nil)
			return(nil);

		// Remove it.
		_recipeList.removeElement(obj);

		return(true);
	}
;
