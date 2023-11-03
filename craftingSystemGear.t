#charset "us-ascii"
//
// craftingSystemGear.t
//
#include <adv3.h>
#include <en_us.h>

#include "craftingSystem.h"

class CraftingThing: CraftingSystemObject, Thing
	syslogID = 'CraftingThing'
;

class CraftingRoom: RuleSchedulerRoom, CraftingThing
	syslogID = 'CraftingRoom'

	becomeCraftingRoom(obj) {
	}
;

class CraftingGear: CraftingThing
	syslogID = 'CraftingGear'
	syslogFlag = 'CraftingGear'
;

class CraftingIngredient: CraftingThing
	syslogID = 'CraftingIngredient'
	syslogFlag = 'CraftingIngredient'
;
