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

Recipe template 'id' @result ->resultLocation?;

RecipeAction template @srcObject | [srcObject] @dstObject | [dstObject] ->action | [action] "recipeAction"?;
RecipeAction template @dstObject | [dstObject] ->action | [action] "recipeAction"?;

#define CRAFTING_SYSTEM_H
