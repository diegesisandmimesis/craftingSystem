#charset "us-ascii"
//
// craftingSystemIngredient.t
//
#include <adv3.h>
#include <en_us.h>

#include "craftingSystem.h"

// Mixin class for in-game objects that are recipe ingredients.
// This is for crafting components that get "used up" as part of
// completing the recipe:  eggs, scraps of metal, collectable plants, and
// so on.  Components that aren't used up (like a workbench
// or a mixing bow) probably want the CraftingGear class.
class CraftingIngredient: CraftingSystemObject
	syslogID = 'CraftingIngredient'
;

// The Ingredient class is for declaring ingredient lists in Recipe
// definitions.  These *refer* to the in-game CraftingIngredient objects,
// but aren't (or shouldn't be) literally the same objects.
class Ingredient: CraftingSystemObject
	syslogID = 'Ingredient'

	// The ingredient itself.  Probably a class name.
	ingredient = nil

	// The gear the ingredient goes in.  If nil, the recipe will
	// assume the ingredient needs to be recipe's resultLocation.
	gear = nil

	// The recipe we're part of.
	recipe = nil

	// Optional method to call when we're added.
	recipeAction = nil

	initializeIngredient() {
		if((location == nil) || !location.ofKind(Recipe))
			return;

		location.addIngredient(self);

		recipe = location;
	}
;
