#charset "us-ascii"
//
// craftingSystemIngredient.t
//
#include <adv3.h>
#include <en_us.h>

#include "craftingSystem.h"

class IngredientList: RecipeStep
	syslogID = 'IngredientList'

	_ingredientList = perInstance(new Vector())

	gear = nil

	addIngredient(obj) {
		if((obj == nil) || !obj.ofKind(Ingredient))
			return(nil);
		_ingredientList.append(obj);
		obj.ingredientList = self;
		return(true);
	}

	removeIngredient(obj) {
		if(_ingredientList.indexOf(obj) == nil)
			return(nil);
		_ingredientList.removeElement(obj);
		return(true);
	}

	recipeAction() {}

	createRecipeTransition(state) {
		local book, rule;

		if((book = _createRecipeTransition(state)) == nil) {
			_error('failed to create transition');
			return(nil);
		}

		if((rule = createRule()) == nil) {
			_error('failed to create rule');
			return(nil);
		}

		book.addRule(rule);
		state.addRulebook(book);

		return(true);
	}

	createReverseTransition(state) {
		local book;
		if((book = _createRecipeTransition(state, true)) == nil) {
			_error('failed to create transition');
			return(nil);
		}
		book.addRule(recipeRule);
		state.addRulebook(book);

		return(true);
	}

	createRule() {
		local r, v;

		r = new IngredientRule();

		if(_testGear(gear))
			v = gear;
		else if(_testGear(recipe.resultLocation))
			v = recipe.resultLocation;
		else
			v = nil;

		if(r.initializeIngredientRule(_ingredientList.toList(), v)
			!= true)
			return(nil);

		recipeRule = r;

		return(r);
	}

	_testGear(v) { return((v != nil) && v.ofKind(CraftingGear)); }

	consumeIngredients() {
		if(recipeRule)
			recipeRule.consumeIngredients();
	}

	recipeStepSetup() {
/*
		if(createReverseTransition() != true) {
			_error('failed to create reverse transition');
			return;
		}
*/
	}
;

class Ingredient: CraftingSystemObject
	syslogID = 'Ingredient'
	syslogFlag = 'Ingredient'

	ingredient = nil
	gear = nil

	ingredientList = nil

	initializeIngredient() {
		if(location == nil)
			return;
		if(!location.ofKind(IngredientList) && !location.ofKind(Recipe))
			return;

		location.addIngredient(self);
	}
;

class IngredientRule: Rule, CraftingSystemObject
	syslogID = 'IngredientRule'

	locations = perInstance(new LookupTable())

	matchRule(data?) {
		local i, l;

		l = locations.keysToList();
		for(i = 1; i <= l.length; i++) {
			if(_matchRuleLocation(l[i], locations[l[i]]) != true)
				return(nil);
		}
		return(true);
	}

	_matchRuleLocation(loc, objs) {
		local b, i, j, l;

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

	initializeIngredientRule(lst, loc) {
		local i;

		if((lst == nil) || !lst.ofKind(List))
			return(nil);

		for(i = 1; i <= lst.length; i++) {
			if(_addBit(lst[i], loc) == nil) {
				_error('failed to add bit');
				return(nil);
			}
		}

		return(true);
	}

	_testGear(v) { return((v != nil) && v.ofKind(CraftingGear)); }

	_addBit(ingr, loc) {
		local v;

		if(_testGear(ingr.gear) == true) 
			v = ingr.gear;
		else if(_testGear(loc) == true)
			v = loc;
		else
			return(nil);

		if(locations[v] == nil)
			locations[v] = new Vector();

		locations[v].append(ingr.ingredient);

		return(true);
	}

	consumeIngredients() {
		locations.keysToList().forEach(function(o) {
			_consumeIngredients(o);
		});
	}

	_consumeIngredients(loc) {
		local l;

		l = loc.allContents();
		l.forEach(function(o) {
			if(o.ofKind(CraftingIngredient))
				o.moveInto(nil);
		});
	}
;
