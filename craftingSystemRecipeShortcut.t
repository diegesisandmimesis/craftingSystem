#charset "us-ascii"
//
// craftingSystemRecipeShortcut.t
//
#include <adv3.h>
#include <en_us.h>

#include "craftingSystem.h"

class RecipeShortcut: CraftingSystemObject
	syslogID = 'RecipeKnowledge'

	// Result class.  This is used to create an Unthing for the result,
	// so commands like >MAKE [result name] will work.
	// Alternately, you can use resultVocab and resultName (below).
	resultClass = nil

	// Vocabulary and name for the result Unthing.  If both of these
	// are specified, they'll override any defined resultClass (above).
	// This is useful if the result is "slice of toast" and you want
	// the vocabulary for the abstract task to be just "toast".
	resultVocab = nil
	resultName = nil

	// The shortcut crafting action (something like >MAKE).
	action = nil

	_unthing = nil

	initializeRecipeShortcut() {
		if((location == nil) || !location.ofKind(Recipe))
			return;
		location.addRecipeShortcut(self);
	}

	setupRecipeShortcut() {
		if((resultVocab != nil) && (resultName != nil)) {
			_unthing = new RecipeUnthing();
			_unthing.vocabWords = resultVocab;
			_unthing.name = resultName;
		} else if(resultClass != nil) {
			_unthing = new RecipeUnthing();
			_unthing.vocabWords = resultClass.vocabWords;
			_unthing.name = resultClass.name;
		} else {
			return;
		}

		_unthing.reinit();
	}

	recipeAction() {}
;

class RecipeUnthing: Unthing
	reinit() {
		initializeVocab();
		addToDictionary(&noun);
		addToDictionary(&adjective);
		addToDictionary(&plural);
		addToDictionary(&adjApostS);
		addToDictionary(&literalAdjective);
	}
;
