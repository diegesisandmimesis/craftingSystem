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
	syslogFlag = 'craftingSystem'
;

craftingSystemPreinit: PreinitObject
	execute() {
		initializeRecipeSteps();
		initializeRecipes();
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

class CraftingSystem: CraftingSystemObject
	_recipeList = perInstance(new Vector())

	addRecipe(obj) {
		if((obj == nil) || !obj.ofKind(Recipe))
			return;
		_recipeList.append(obj);
	}

	listRecipes() {}
;
