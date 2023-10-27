#charset "us-ascii"
//
// craftingSystemGear.t
//
#include <adv3.h>
#include <en_us.h>

#include "craftingSystem.h"

class CraftingGear: CraftingSystemObject, Thing
	syslogID = 'CraftingGear'
	syslogFlag = 'CraftingGear'
;

class CraftingIngredient: CraftingSystemObject, Thing
	syslogID = 'CraftingIngredient'
	syslogFlag = 'CraftingIngredient'
;
