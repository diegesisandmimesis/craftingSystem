#charset "us-ascii"
//
// craftingSystemRecipe.t
//
//	The Recipe class.  It's a special kind of state machine that's
//	mostly linear and produces something in the final state.
//
#include <adv3.h>
#include <en_us.h>

#include "craftingSystem.h"

// Recipe is a special kind of state machine.
class Recipe: StateMachine, CraftingSystemObject
	syslogID = 'Recipe'
	syslogFlag = 'Recipe'

	// Recipe ID.
	recipeID = nil

	// What the recipe produces.  Probably a Thing class.
	result = nil

	// Optional location for the result to appear.  This will ALSO
	// be used as the default "mixing" location for ingredients, unless
	// a different location is specified in the ingredient list or on
	// the individual ingredients.
	resultLocation = nil

	// Set by IngredientAction when changing the resultLocation
	_resultLocationFlag = nil

	// The CraftingSystem we're part of.
	craftingSystem = nil

	// If defined, this recipe is only active in the given location.
	craftingLocation = nil

	// Ordered list of the recipe steps.
	_recipeStep = perInstance(new Vector())

	// RecipeShortcut instance for this recipe, if defined.
	_recipeShortcut = nil

	// Does everyone start out knowing this recipe?
	startKnown = nil

	// Table of who knows this recipe.  Keys are actors, values are boolean
	// true if that actor knows this recipe, undefined otherwise.
	_knowledgeTable = perInstance(new LookupTable())

	// We're a StateEngine, which is a RuleEngine.  Here we
	// add a couple of options for figuring out what scheduler to use.
	initializeRuleEngine() {
		if(_tryRuleScheduler(craftingLocation) == true)
			return;
		if(location &&
			(_tryRuleScheduler(location.craftingLocation) == true))
			return;
		inherited();
	}

	// Called at preinit.
	initializeRecipe() {
		// Add the recipe to the crafting system.
		initializeRecipeCraftingSystem();

		// "Compile" the recipe.
		compileRecipe();
	}

	// Add this recipe to its crafting system.
	initializeRecipeCraftingSystem() {
		if((location == nil) || !location.ofKind(CraftingSystem))
			return;
		location.addRecipe(self);
	}

	addRecipeShortcut(obj) {
		if((obj == nil) || !obj.ofKind(RecipeShortcut))
			return(nil);

		_recipeShortcut = obj;
		obj.recipe = self;

		return(true);
	}

	clearResultLocationFlag() {
		if(_resultLocationFlag == nil)
			return;
		_resultLocationFlag = nil;
		resultLocation = nil;
	}

	setLocationFlag(loc) {
		resultLocation = loc;
		_resultLocationFlag = true;
	}

	// Returns the "bottommost" ingredient list.
	// Ingredients can be added directly to the recipe (instead of
	// explicitly to an ingredient list).  If that happens, this is
	// how we figure out what ingredient list to use.
	// This is intended to be used during preinit, as the _recipeStep
	// list is being constructed (and so the last ingredient list
	// in _recipeStep might be changing).
	getIngredientList() {
		local i;

		// Walk backwards through the recipe steps, returning
		// the first (last) ingredient list we find.
		for(i = _recipeStep.length; i > 0; i--) {
			if(_recipeStep[i].ofKind(IngredientList))
				return(_recipeStep[i]);
		}

		// Didn't find anything.
		return(nil);
	}

	// If an ingredient is added directly to the recipe, get the
	// "bottommost" ingredient list and add the ingredient to it.
	// If there is not ingredient list, create one, add it to the
	// recipe, and use it.
	addIngredient(obj) {
		local lst;

		// Make sure the arg is an Ingredient.
		if((obj == nil) || !obj.ofKind(Ingredient))
			return(nil);

		// Get the most recently added ingredient list.  If
		// none exists, create a new ingredient list and add it
		// to the recipe steps.
		if((lst = getIngredientList()) == nil) {
			lst = new IngredientList();
			addRecipeStep(lst);
		}

		// Add the ingredient to the list.
		lst.addIngredient(obj);

		return(true);
	}

	// Add a recipe step to our list.
	addRecipeStep(obj) {
		if((obj == nil) || !obj.ofKind(RecipeStep))
			return;

		// Remember what recipe the step is a part of.
		obj.recipe = self;

		_recipeStep.append(obj);
	}

	// Add a recipe state.
	addRecipeState(obj) {
		if((obj == nil) || !obj.ofKind(RecipeState))
			return(nil);

		// Remember what recipe the state is a part of.
		obj.recipe = self;

		return(addState(obj));
	}

	// Remove the given state from the recipe.
	removeRecipeState(obj) { return(removeState(obj)); }

	// Stub method.  Called when the recipe is completed.
	recipeAction() {}

	// Produce whatever the recipe produces.
	// Called after the final recipe transition.
	produceResult(silent?) {
		local loc;

		// If we have no result defined, nothing to do.
		if(result == nil)
			return;

		// If we have a location for the result, use it.  Otherwise
		// we punt by assuming it goes into whatever location the
		// gActor is in.
		if(resultLocation)
			loc = resultLocation;
		else
			loc = gActor.location;

		// Figure out if we have one result or many.
		if(result.ofKind(List)) {
			result.forEach(function(o) {
				_produceSingleResult(o, loc);
			});
		} else {
			_produceSingleResult(result, loc);
		}

		learnRecipe(gActor);

		if(silent == true) {
			gTranscript.deactivate();
			recipeOutputFilter.activate();
		}

		// If we have further stuff to do on recipe completion, we
		// do it now.
		recipeAction();

		if(silent == true) {
			recipeOutputFilter.deactivate();
			gTranscript.activate();
		}
	}

	// Produce a single recipe result.
	_produceSingleResult(cls, loc) {
		local obj;

		if(cls == nil)
			return;

		obj = cls.createInstance();
		obj.moveInto(loc);
	}

	// Consume all the ingredients used in the recipe, by telling
	// each recipe step to consume its associated ingredients.
	consumeIngredients(fromActor?) {
		_recipeStep.forEach(function(o) {
			if(!o.ofKind(IngredientList))
				return;
			o.consumeIngredients(fromActor);
		});
	}

	validateStateTransition() {
		// If the state ID is changing, always okay.
		if(_nextStateID != stateID)
			return(true);

		// If the state ID is NOT changing, it's only okay
		// if we only have one state.
		return(_stateStack.length == 1);
	}

	checkRecipeLocation() {
		if(craftingLocation == nil)
			return(true);
		if(gActor.getOutermostRoom() != craftingLocation)
			return(nil);
		return(true);
	}

	isKnownBy(actor) {
		if(actor == nil) return(nil);
		if(startKnown == true) return(true);
		return(_knowledgeTable[actor] == true);
	}

	learnRecipe(actor) {
		if(actor == nil) return(nil);
		_knowledgeTable[actor] = true;
		return(true);
	}

	// Get all the ingredients for this recipe that the given actor
	// CANNOT currently access.
	getMissingIngredients(actor) {
		local l;

		// Make sure the arg is an actor.
		if((actor == nil) || !actor.ofKind(Actor))
			return(nil);

		// Vector of all the missing ingredients.
		l = new Vector();

		// Go through the recipe steps.
		_recipeStep.forEach(function(o) {
			local v;

			// We only care about ingredient lists.
			if(!o.ofKind(IngredientList))
				return;

			// Ask the ingredient list which ingredients in
			// it the actor can't currently access.
			v = o.getMissingIngredients(actor);

			// If there are none, we're done here.
			if(v == nil)
				return;

			// Iterate through the list of missing ingredients
			// from this step, adding them to the "master" list.
			// We COULD just use l += v, but that would create
			// a new Vector instead of just expanding the old one.
			v.forEach(function(u) { l.append(u); });
		});

		// If we have missing ingredients, return the list.
		if(l.length > 0)
			return(l.toList());

		// Nope, return nil.
		return(nil);
	}

	isGear(obj) {
		return((obj != nil) && obj.ofKind(CraftingGear));
	}

	getMissingGear(actor) {
		local l;

		// Make sure the arg is an actor.
		if((actor == nil) || !actor.ofKind(Actor))
			return(nil);

		// Vector of all the missing gear.
		l = new Vector();

		if(resultLocation != nil) {
			if(!actor.canTouch(resultLocation))
				l.append(resultLocation);
		}

		// Go through the recipe steps.
		_recipeStep.forEach(function(o) {
			local v;

			// We only care about ingredient lists.
			if(!o.ofKind(IngredientList))
				return;

			// Ask the ingredient list which ingredients in
			// it the actor can't currently access.
			v = o.getMissingGear(actor);

			// If there are none, we're done here.
			if(v == nil)
				return;

			// Iterate through the list of missing ingredients
			// from this step, adding them to the "master" list.
			// We COULD just use l += v, but that would create
			// a new Vector instead of just expanding the old one.
			v.forEach(function(u) { l.append(u); });
		});

		// If we have missing ingredients, return the list.
		if(l.length > 0)
			return(l.toList());

		// Nope, return nil.
		return(nil);
	}
;

recipeOutputFilter: OutputFilter
	isActive = nil
	activate() { isActive = true; }
	deactivate() { isActive = nil; }
	filterText(ostr, val) { return(isActive ? '' : inherited(ostr, val)); }
;

recipeFilterPreinit: PreinitObject
	execute() {
		mainOutputStream.addOutputFilter(recipeOutputFilter);
	}
;
