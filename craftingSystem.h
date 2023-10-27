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

Recipe template 'recipeID' @result? ->resultLocation? "recipeAction"?;

IngredientList template 'stepID'? ->gear? "recipeAction"?;
Ingredient template @ingredient ->gear?;

RecipeStep template 'stepID'? "recipeAction"?;

RecipeAction template 'stepID'? @srcObject | [srcObject] @dstObject | [dstObject] ->action | [action] "recipeAction"?;
RecipeAction template 'stepID'? @dstObject | [dstObject] ->action | [action] "recipeAction"?;

#define CRAFTING_SYSTEM_H
