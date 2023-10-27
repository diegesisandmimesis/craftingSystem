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

	canonicalizeAsList(l) {
		if(l == nil) return(nil);
		if(l.ofKind(Vector)) return(l.toList());
		if(!l.ofKind(List)) return([ l ]);
		return(l);
	}
;

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

class CraftingSystem: CraftingSystemObject
	_recipeList = perInstance(new Vector())

	addRecipe(obj) {
		if((obj == nil) || !obj.ofKind(Recipe))
			return;
		_recipeList.append(obj);
	}

	listRecipes() {}
;
