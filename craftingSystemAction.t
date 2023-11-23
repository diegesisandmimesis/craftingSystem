#charset "us-ascii"
//
// craftingSystemAction.t
//
#include <adv3.h>
#include <en_us.h>

#include "craftingSystem.h"

// Crafting system shortcut action messages.
// These are fall-back generic defaults.  They will be overridden by a
// property of the same name on either the recipe shortcut declaration or
// the crafting Action declaration (in that order)
modify playerActionMessages
	cantCraftHere = '{You/he} can\'t do that here. '
	cantCraftRecipeUnknown = '{You/He} do{es}n\'t know how to make that. '
	cantCraftThat = '{You/He} can\'t make that. '

	cantCraftObj(obj) {
		return('{You/he} can\'t make <<obj.name>>. ');
	}

	cantCraftMissingIngredients(lst) {
		return('{You/He} can\'t make that, {you/he} need{s}
			\v<<stringLister.makeSimpleList(lst)>>. ');
	}

	cantCraftMissingGear(lst) {
		return('{You/He} can\'t make that, {you/he} need{s}
			\v<<stringLister.makeSimpleList(lst)>>. ');
	}
;

// PreCondition that checks if the crafting action can occur in the current
// location.
canCraftHere: PreCondition
	checkPreCondition(obj, allowImplicit) {
		if(obj == nil)
			obj = gDobj;

		// If we're not trying to craft a craftable item, fail.
		if(!obj.ofKind(RecipeShortcutCraftable)) {
			reportFailure(&cantCraftThat);
			return;
		}

		if(gAction.craftingLocation != nil) {
			obj.verifyCraftingLocation(gAction.craftingLocation);
			if(!gActor.isIn(gAction.craftingLocation)) {
				reportFailure(gAction.cantCraftHere);
				exit;
			}
		}
	}
;

canCraft: PreCondition
	verifyPreCondition(obj) {
		if(obj == nil)
			obj = gDobj;

		if(!obj.ofKind(RecipeShortcutCraftable)) {
			illogical(&cantCraftThat);
			return;
		}

		obj.verifyShortcut();
	}
;

class _CraftAction: Action;

class CraftAction: _CraftAction, TAction
	preCond = [ canCraftHere, canCraft ]

	// If defined, this action can only be done in the given location.
	craftingLocation = nil

	// Verb to use in informational messages:  "You can't craft that. "
	// and so on.
	craftingVerb = 'craft'

	// Add RecipeShortcutCraftable instances to crafting actions'
	// default scope.
	objInScope(obj) {
		local r;

		r = inherited(obj);
		if(r == true)
			return(true);

		if(obj.ofKind(RecipeShortcutCraftable)) {
			return(true);
		}

		return(nil);
	}

	cantCraftObj = nil
	cantCraftHere = nil
	cantCraftRecipeUnknown = nil
	cantCraftThat = nil

	execAction() {
		if((gDobj == nil) || !gDobj.ofKind(RecipeShortcutCraftable)) {
			reportFailure(&cantCraftThat);
			return;
		}

		_craftingAction();
	}

	_craftingAction() {
		craftingAction();
		gDobj.craftingAction();
	}

	craftingAction() {}
;
