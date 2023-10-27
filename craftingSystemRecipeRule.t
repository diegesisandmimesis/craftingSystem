#charset "us-ascii"
//
// craftingSystemRecipeRule.t
//
#include <adv3.h>
#include <en_us.h>

#include "craftingSystem.h"

class RecipeRule: Rule
	recipeStep = nil

	matchRule() {
		if(recipeStep == nil)
			return(nil);
		return(recipeStep.matchRule());
	}
;

class IngredientRule: RecipeRule
	ingredient = nil
	gear = nil

	matchRule() {
		// Special case.  The desired location for the ingredient
		// is nil.
		if(gear == nil)
			return(ingredient.location == nil);
		
aioSay('\ningredient = <<toString(ingredient.name)>>\n ');
aioSay('\nmatchRule() = <<toString(ingredient.location == gear)>>\n ');
		return(ingredient.location == gear); }
;
