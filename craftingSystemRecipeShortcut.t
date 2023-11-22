#charset "us-ascii"
//
// craftingSystemRecipeShortcut.t
//
//	Classes and logic for recipe shortcuts.
//
//	This includes
//
//		RecipeShortcutObject
//			General methods for checking shortcut action
//			preconditions
//
//		RecipeShortcut
//			Class for shortcut declarations.  Gets methods
//			called from the generic CraftAction action (and its
//			preconditions)
//
//		RecipeShortcutCraftable
//			Base class for RecipeUnthing and Craftable.  Includes
//			the methods needed for CraftAction.
//
//		RecipeUnthing
//			Class for recipe result Unthings.  An Unthing instance
//			is automatically created for each recipe result, to
//			handle the vocabulary for actions like >MAKE TOAST
//			when there's no existing toast object around
//
//
#include <adv3.h>
#include <en_us.h>

#include "craftingSystem.h"

class RecipeShortcutObject: CraftingSystemObject
	_getProp(prop, obj?) {
		local v;

		if((v = (obj ? self.(prop)(obj) : self.(prop))) != nil)
			return(v);
		if((v = (obj ? gAction.(prop)(obj) : gAction.(prop))) != nil)
			return(v);

		return(nil);
	}

	_illogical(prop, obj?) {
		local v;

		if((v = _getProp(prop, obj)) != nil)
			illogical(v);
		if(obj)
			illogical(prop, obj);
		else
			illogical(prop);
	}

	_reportFailure(prop, obj?) {
		local v;

		if((v = _getProp(prop, obj)) != nil) {
			reportFailure(v);
		} else {
			if(obj)
				reportFailure(prop, obj);
			else
				reportFailure(prop);
		}
		exit;
	}

;

class RecipeShortcut: RecipeShortcutObject
	syslogID = 'RecipeShortcut'

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

	// The recipe we're a shortcut for.
	recipe = nil

	// An Unthing for whatever the recipe produces.
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

		_unthing.recipe = recipe;
		_unthing.shortcut = self;

		_unthing.reinit();
	}

	// Called by canCraft precondidition.
	_verifyShortcut() {
		local r;

		verifyShortcut();
		if(recipe.isKnownBy(gActor) != true) {
			_illogical(&cantCraftRecipeUnknown);
			return;
		}
		if((r = getMissingGear()) != nil) {
			_illogical(&cantCraftMissingGear, r);
			return;
		}
		if((r = getMissingIngredients()) != nil) {
			_illogical(&cantCraftMissingIngredients, r);
			return;
		}
	}

	getMissingIngredients() {
		if(recipe == nil)
			return(nil);
		return(recipe.getMissingIngredients(gActor));
	}

	getMissingGear() {
		if(recipe == nil)
			return(nil);
		return(recipe.getMissingGear(gActor));
	}

	verifyShortcut() {}

	// Called by canCraftHere precondition.
	_verifyCraftingLocation(loc) {
		verifyCraftingLocation(loc);
		if(!gActor.isIn(loc))
			_reportFailure(&cantCraftHere);
		_reportFailure(&cantCraftHere);
	}

	verifyCraftingLocation(loc) {}

	cantCraftObj = nil
	cantCraftHere = nil
	cantCraftRecipeUnknown = nil
	cantCraftThat = nil

	// Called from RecipeShortcutCraftable._craftingActionShortcut(),
	// this is where we actually produce the recipe result.
	// The assumption is that individual shortcuts *probably* won't
	// need to overwrite this, and that they'll usually just use
	// shortcutAction() to display a shortcut-specific action
	// message.
	recipeAction() {
		recipe.consumeIngredients(gActor);
		recipe.produceResult(true);
		shortcutAction();
	}

	// Shortcut-specific action.  Intended to do shortcut-specific
	// stuff, like outputting an abbreviated custom description of
	// making the recipe.
	shortcutAction() {}
;

// Base class for both RecipeUnthing and Craftable.  Includes methods
// needed for CraftAction.
class RecipeShortcutCraftable: RecipeShortcutObject
	// Props for caching results.
	// We have to do this because we could either be an Unthing (if
	// the player's context doesn't include a copy of whatever is being
	// crafted) or a Thing (if the player already has one of the
	// thing being crafted).
	recipe = nil		// recipe we're part of
	shortcut = nil		// shortcut for our recipe
	result = nil		// result of our recipe

	// Get our recipe's result.
	getResult() {
		local r;

		// Only check if we don't already know.
		if(result == nil) {
			if(ofKind(Craftable)) {
				// If we're a craftable object, our recipe's
				// result is ourself.
				result = self;
			} else if(ofKind(RecipeUnthing)) {
				// If we're an Unthing, then we have to look
				// up our recipe's result.
				if((r = getRecipe()) == nil)
					return(nil);
				result = r.result;
			} else {
				// Weirdness, fail.
				result = nil;
			}
		}

		return(result);
	}

	// Return our recipe.
	getRecipe() {
		if(recipe == nil) {
			// The only case we care about is if we're
			// a craftable object, in which case we can look
			// up our recipe in via the crafting system manager
			// singleton.  If we're NOT a craftable, the we're
			// almost certainly a RecipeUnthing, in which case we
			// SHOULD know our recipe, because it will have been
			// set when we were created.
			if(ofKind(Craftable))
				recipe = gRecipeFor(self);
		}
		return(recipe);
	}

	// Get our recipe shortcut.
	getShortcut() {
		local r;

		if(shortcut == nil) {
			// We just look it up in the recipe.
			if((r = getRecipe()) == nil)
				return(nil);
			shortcut = r._recipeShortcut;
		}

		return(shortcut);
	}

	// Called by the canCraft precondition.
	verifyShortcut() {
		local s;

		if((s = getShortcut()) == nil) {
			_illogical(&cantCraftObj, self);
			return;
		}
		s._verifyShortcut();
	}

	// Called by the canCraftHere precondition if the crafting action
	// has an explicit crafting location defined.
	verifyCraftingLocation(loc) {
		local s;

		if(loc == nil)
			return;
		if((s = getShortcut()) == nil)
			return;
		s._verifyCraftingLocation(loc);
	}

	// We punt off to the shortcut itself, because that's the thing
	// that has to have an explicit declaration if it exists.
	// Craftable object instances that want to overwrite this can
	// do so in their own declarations.
	_craftingActionShortcut() {
		local s;

		if((s = getShortcut()) == nil)
			return;
		s.recipeAction();
	}

	// Called by our dobjFor([whatever the crafting action is])
	// handler.
	craftingAction() { _craftingActionShortcut(); }
;

class RecipeUnthing: RecipeShortcutCraftable, Unthing
	shortcut = nil

	reinit() {
		initializeVocab();
		addToDictionary(&noun);
		addToDictionary(&adjective);
		addToDictionary(&plural);
		addToDictionary(&adjApostS);
		addToDictionary(&literalAdjective);
	}

	craftingAction() {
		local r;

		if((r = getResult()) != nil) {
			r.craftingAction();
			return;
		}
		inherited();
	}
;

