//
// craftingSystem.h
//

// Uncomment to enable debugging options.
//#define __DEBUG_CRAFTING_SYSTEM

#include "stateMachine.h"
#ifndef STATE_MACHINE_H
#error "This module requires the stateMachine module."
#error "https://github.com/diegesisandmimesis/stateMachine"
#error "It should be in the same parent directory as this module.  So if"
#error "craftingSystem is in /home/user/tads/craftingSystem, then"
#error "stateMachine should be in /home/user/tads/stateMachine ."
#endif // STATE_MACHINE_H

//CraftingSystem 'craftingSystemID'? ->craftingLocation;

Recipe template 'recipeID' @result? ->resultLocation? "recipeAction"?;
//Recipe template 'recipeID' @result? ->resultLocation? ->craftingLocation? "recipeAction"?;

RecipeShortcut template 'resultVocab' 'resultName' ->action "recipeAction"?;
RecipeShortcut template @resultClass ->action "recipeAction"?;

IngredientList template 'stepID'? ->gear? "recipeAction"?;
Ingredient template @ingredient ->gear?;

RecipeStep template 'stepID'? "recipeAction"?;

RecipeStepWithTrigger template 'stepID'? @srcObject | [srcObject] \
	@dstObject | [dstObject] ->action | [action] "recipeAction"?;
RecipeStepWithTrigger template 'stepID'? @dstObject | [dstObject] \
	->action | [action] "recipeAction"?;

#define gRecipeFor(obj) (craftingSystemManager.getRecipeFor(obj))
#define gRecipesFor(obj) (craftingSystemManager.getRecipesFor(obj))

#define DefineCraftingAction(name) \
	modify RecipeShortcutCraftable \
		dobjFor(name) { \
			verify() {} \
			action() { craftingAction(); } \
		} \
	; \
	DefineTActionSub(name, CraftAction)

#define CRAFTING_SYSTEM_H
