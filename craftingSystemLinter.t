#charset "us-ascii"
//
// craftingSystemLinter.t
//
#include <adv3.h>
#include <en_us.h>

#include "craftingSystem.h"

#ifdef __DEBUG

// verify that the result has the Craftable class
modify ruleEngineLinter
	execBeforeMe = inherited + [
		ruleEnginePreinit,
		craftingSystemPreinit
	]

	logName = 'crafting system linter'

	lint() {
		inherited();
	}
;
+LintClass @Recipe
	lintAction(obj) {
		if(obj.result == nil) {
			error('recipe without result,
				recipeID <q><<toString(obj.recipeID)>></q>');
			return;
		}
		if(!obj.result.ofKind(Craftable)) {
			if(obj._recipeShortcut != nil)
				error('recipe with shortcut has result not
					Craftable, recipeID
					<q><<toString(obj.recipeID)>></q>');
			else
				warning('recipe has result not Craftable,
					recipeID
					<q><<toString(obj.recipeID)>></q>');
		}

	}
;

#endif // __DEBUG
