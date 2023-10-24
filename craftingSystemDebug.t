#charset "us-ascii"
//
// craftingSystemDebug.t
//
#include <adv3.h>
#include <en_us.h>

#include "craftingSystem.h"

#ifdef __DEBUG_CRAFTING_SYSTEM

DefineSystemAction(CSList)
	execSystemAction() {
		"Crafting system debugging info: ";
		"<.p> ";
		forEachInstance(CraftingSystem, function(o) {
			o.listRecipes();
		});
	}
;
VerbRule(CSList) 'cslist': CSListAction verbPhrase = 'cslist/cslisting';

modify CraftingSystem
	listRecipes() {
		"Crafting system <<toString(self)>>:\n ";
		_recipeList.forEach(function(o) {
			"\tRecipe <q><<o.id>></q>\n ";
			o.listRecipeSteps();
			"<.p> ";
			o.printStateMachine();
			"<.p> ";
			"\n ";
		});
	}
;

modify Recipe
	listRecipeSteps() {
		_recipeSteps.forEach(function(o) {
			"\t\tRecipe step <q><<o.id>></q>\n ";
			o.listRecipeStep();
			"\n ";
		});
	}
	printStateMachine() {
		"\t\tState Machine:\n ";
		if(_stateMachine == nil) {
			"\t\t\tNIL\n ";
			return;
		}
		_stateMachine.fsmState.keysToList().forEach(function(o) {
			"\t\t\tstate <<toString(o)>>\n ";
		});
	}
;

modify RecipeStep
	listRecipeStep() {
		"\t\t\tsrcObject = <<toString(srcObject)>>\n ";
		"\t\t\tdstObject = <<toString(dstObject)>>\n ";
		"\t\t\taction = <<toString(action)>>\n ";
	}
;

#endif // __DEBUG_CRAFTING_SYSTEM
