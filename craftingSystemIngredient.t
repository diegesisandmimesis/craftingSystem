#charset "us-ascii"
//
// craftingSystemIngredient.t
//
#include <adv3.h>
#include <en_us.h>

#include "craftingSystem.h"

class IngredientSwap: RecipeAction
	syslogID = 'IngredientSwap'

	_recipeAction() {
		clearResultLocationFlag();
		if(recipe.resultLocation == nil) {
			if(gIobj.ofKind(CraftingIngredient))
				recipe.setLocationFlag(gIobj.location);
			else if(gDobj.ofKind(CraftingIngredient))
				recipe.setLocationFlag(gDobj.location);
		}
		consumeIngredients();
		recipeAction();
	}
;

// IngredientList is a specialized subclass of RecipeStep.  It creates
// a new state (whatever happens after the ingredients are all assembled)
// and TWO transitions:  one to the new state from whatever the current
// state before the ingredient list is;  and one from the new state back
// to whatever the current state (before the ingredient list) is.
class IngredientList: RecipeStepWithState
	syslogID = 'IngredientList'

	// Location where all the ingredients are assembled.  Individual
	// ingredients can override this (to required that they be in
	// some other location).
	// Usually a CraftingGear instance (mixing bowl, workbench, something
	// like that).
	gear = nil

	// Vector to hold all our ingredients
	_ingredientList = perInstance(new Vector())

	// Add an ingredient to our list.
	addIngredient(obj) {
		// Make sure the ingredient is valid.
		if((obj == nil) || !obj.ofKind(Ingredient))
			return(nil);

		_ingredientList.append(obj);
		obj.ingredientList = self;

		return(true);
	}

	// Remove an ingredient from our list.
	removeIngredient(obj) {
		// Make sure the ingredient is on the list.
		if(_ingredientList.indexOf(obj) == nil)
			return(nil);

		_ingredientList.removeElement(obj);

		return(true);
	}

	// Called by the recipe compiler, this creates the transitions
	// for the ingredient list.
	createRecipeTransitions(fromState, toState, last?) {
		local book0, book1, rule0, rule1;

		// First we create the "forward" transition, from the
		// state before the ingredient list to the state produced
		// by completing the ingredient list.
		if((book0 = _createRecipeTransition(fromState, toState, last))
			== nil) {
			_error('failed to create transition');
			return(nil);
		}

		// Create the rule.  The rule checks that all the ingredients
		// are where they're supposed to be.
		if((rule0 = createRule()) == nil) {
			_error('failed to create rule');
			return(nil);
		}

		// Add the new rule to the transition and the transition to
		// the state.
		book0.addRule(rule0);
		fromState.addRulebook(book0);

		// Now we create the "reverse" transition, from the "all
		// the ingredients are in place" state back to the state
		// before the ingredient list.
		// This is to handle the case where everything is in place
		// at some point, then one or more ingredient is removed.
		if((book1 = _createRecipeTransition(toState, fromState))
			== nil) {
			_error('failed to create transition');
			return(nil);
		}

		// Create the rule for the "reverse" transition.  We
		// use a special rule class.  It contains a reference to
		// the "forward" rule, and just checks for the negation of
		// the "forward" rule's condition(s).  This is just to save
		// having to do all the checks twice.
		rule1 = new IngredientRuleReverse();
		rule1.ingredientRule = rule0;

		// Add the "reverse" rule to the "reverse" transition, and
		// the "reverse" transition to the "all the ingredients in
		// place" state.
		book1.addRule(rule1);
		toState.addRulebook(book1);

		return(true);
	}

	// Create the ingredient rule.
	// This is a single rule that check the location of the entire
	// ingredient list.
	createRule() {
		local r, v;

		// We have a special class for the ingredient rule.
		r = new IngredientRule();

		// Try to figure out where all the ingredients need to be.
		// This is either declared on the ingredient list, declared
		// on the recipe (the place where the recipe result goes),
		// or nil.
		// This is just a fallback--individual ingredients can have
		// locations declared individually on them, and that takes
		// precidence.
		if(_testGear(gear))
			v = gear;
		else if(_testGear(recipe.resultLocation))
			v = recipe.resultLocation;
		else
			v = nil;

		// Tell the rule to intitialze itself with our ingredients
		// and the default location we figured out above.
		if(r.initializeIngredientRule(_ingredientList.toList(), v)
			!= true)
			return(nil);

		// Remember our rule.
		recipeRule = r;

		return(r);
	}

	// The location for ingredients, by default, needs to exist and
	// be an instance of CraftingGear.
	_testGear(v) { return((v != nil) && v.ofKind(CraftingGear)); }

	// Consume our ingredients.
	consumeIngredients() {
		// We delegate the task to the rule;  it knows where
		// everything is.
		if(recipeRule)
			recipeRule.consumeIngredients();
	}

	// Stub method.
	recipeAction() {}
;

// Class for ingredient declarations.
// This isn't the in-game object or objects, this is for the entry in
// the ingredient list.
class Ingredient: CraftingSystemObject
	syslogID = 'Ingredient'
	syslogFlag = 'Ingredient'

	// Reference to the ingredient's object or class.
	ingredient = nil

	// Location where the ingredient needs to be.
	gear = nil

	// The ingredient list we're part of.
	ingredientList = nil

	// Called at preinit.  We add ourselves to our ingredient list.
	initializeIngredient() {
		if(location == nil)
			return;

		if(!location.ofKind(IngredientList) && !location.ofKind(Recipe))
			return;

		location.addIngredient(self);
	}
;

// Class for matching the location of a bunch of ingredients.
class IngredientRule: Rule, CraftingSystemObject
	syslogID = 'IngredientRule'

	// Hash table for all the places that need ingredients.
	locations = perInstance(new LookupTable())

	// Standard Rule method, returns boolean true if all our ingredients
	// are in the right place, nil otherwise.
	matchRule(data?) {
		local i, l;

		// We go through all the ingredient locations (containers
		// or whatever) and make sure their contents match the
		// conditions of the ingredient list.
		l = locations.keysToList();
		for(i = 1; i <= l.length; i++) {
			// If any match fails, we immediately fail.
			if(_matchRuleLocation(l[i], locations[l[i]]) != true)
				return(nil);
		}

		// If no check failed, it's a success.
		return(true);
	}

	// Check to make sure the given location contains all the given
	// objects, and all the objects are in the given location.
	_matchRuleLocation(loc, objs) {
		local b, i, j, l;

		// Get everything in the location, including nested objects.
		l = loc.allContents();

		// If the container doesn't contain as many items as there
		// are in the ingredient list, we're clearly not done.
		if(l.length != objs.length)
			return(nil);

		// Now we check the container to make sure everything in
		// it is in the ingredient list.
		for(i = 1; i <= l.length; i++) {
			b = nil;
			for(j = 1; (j <= objs.length) && (b == nil); j++) {
				if((l[i] == objs[j]) || l[i].ofKind(objs[j])) {
					b = true;
				}
			}
			if(b == nil)
				return(nil);
		}

		// We ALSO check to make sure everything on the ingredient
		// list is in the container.
		for(i = 1; i <= objs.length; i++) {
			b = nil;
			for(j = 1; (j <= l.length) && (b == nil); j++) {
				if((l[i] == objs[j]) || l[i].ofKind(objs[j]))
					b = true;
			}
			if(b == nil)
				return(nil);
		}

		return(true);
	}

	// Initialize our condition(s).
	// Args are, in order, the ingredient list and the default location
	// to check for them.
	initializeIngredientRule(lst, loc) {
		local i;

		// We need an ingredient list.
		if((lst == nil) || !lst.ofKind(List))
			return(nil);

		// Go through the list and add each one to our list
		for(i = 1; i <= lst.length; i++) {
			if(_addIngredientCondition(lst[i], loc) == nil) {
				_error('failed to add bit');
				return(nil);
			}
		}

		return(true);
	}

	// Make sure the arg exists and is an instance of CraftingGear.
	_testGear(v) { return((v != nil) && v.ofKind(CraftingGear)); }

	// Add the location condition for a single ingredient.
	// Args are the Ingredient instance (from the ingredient list)
	// and a default location (which may or may not be used).
	_addIngredientCondition(ingr, loc) {
		local v;

		// Work out where the ingredient should be or die
		// trying.
		if(_testGear(ingr.gear) == true) 
			v = ingr.gear;
		else if(_testGear(loc) == true)
			v = loc;
		else
			return(nil);

		// The locations table is a hash table keyed by location
		// and with values which are arrays of ingredients that
		// should be in that location.

		// If the vector for this location doesn't exist, create one.
		if(locations[v] == nil)
			locations[v] = new Vector();

		// Add the ingredient to the array for this location.
		locations[v].append(ingr.ingredient);

		return(true);
	}

	// Consume all of our ingredients.
	consumeIngredients() {
		locations.keysToList().forEach(function(o) {
			_consumeIngredients(o);
		});
	}

	// Consume all the ingredients in the given location.
	_consumeIngredients(loc) {
		local l;

		l = loc.allContents();
		l.forEach(function(o) {
			if(o.ofKind(CraftingIngredient))
				o.moveInto(nil);
		});
	}
;

// Special class for "reverse" ingredient rules.
// This just matches the boolean negation of the "forward" ingredient rule.
// That is, if the "forward" rule answers "are all the ingredients in place",
// this answers "are any ingredients out of place".
// Used for the "reverse" transition.
class IngredientRuleReverse: Rule, CraftingSystemObject
	syslogID = 'IngredientRuleReverse'

	ingredientRule = nil

	matchRule(data?) {
		if(ingredientRule == nil)
			return(nil);
		return(!ingredientRule.check());
	}
;
