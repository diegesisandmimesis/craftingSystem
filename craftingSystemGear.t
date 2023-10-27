#charset "us-ascii"
//
// craftingSystemGear.t
//
#include <adv3.h>
#include <en_us.h>

#include "craftingSystem.h"

class CraftingGear: CraftingSystemObject
	syslogID = 'CraftingGear'

	// Returns true if we contain at least one instance of the given
	// class.
	containsAtLeastOneOf(cls) {
		local i, l;

		l = allContents();
		for(i = 1; i <= l.length; i++) {
			if((l[i] == cls) || l[i].ofKind(cls))
				return(true);
		}

		return(nil);
	}

	// Returns true if everything in our contents is an instance of
	// the given class.
	containsOnly(cls) {
		local i, l;

		l = allContents();
		for(i = 1; i <= l.length; i++) {
			if((l[i] != cls) && !l[i].ofKind(cls))
				return(nil);
		}

		return(true);
	}

	containsOnlyA(cls) {
		if(containsAtLeastOneOf(cls) != true)
			return(nil);
		return(allContents().length == 1);
	}
;

