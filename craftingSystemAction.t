#charset "us-ascii"
//
// craftingSystemAction.t
//
#include <adv3.h>
#include <en_us.h>

#include "craftingSystem.h"

#ifdef CRAFTING_SYSTEM_ACTION

modify playerActionMessages
	cantMakeThat = '{You/he} can\'t make that. '
;

DefineTAction(Make);
VerbRule(Make)
	'make' singleDobj
	: MakeAction
	verbPhrase = 'make/making (what)'

	objInScope(obj) {
		local r;

		if((r = inherited(obj)) == true)
			return(true);

		return(r);
	}
;

modify Thing dobjFor(Make) { verify() { illogical(&cantMakeThat); } };

#endif // CRAFTING_SYSTEM_ACTION
