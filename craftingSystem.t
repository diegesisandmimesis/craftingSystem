#charset "us-ascii"
//
// craftingSystem.t
//
//	A module for implementing crafting systems in TADS3.
//
//
// DECLARING A CRAFTING SYSTEM
//
//	First, each game needs to define exactly one RuleEngine instance.
//	It doesn't need to be modified (or even named).
//
//		// Declare a RuleEngine instance.
//		RuleEngine;
//
//	Next comes a CraftingSystem declaration.  Like the RuleEngine
//	declaration, it can be just the class name.  But in most cases
//	you'll probably want to give it a name so you can refer to it
//	elsewhere in your code:
//
//		// Declare the crafting system.
//		cookingSystem: CraftingSystem;
//
//	Now you can declare recipes as belonging to the crafting system
//	using the standard TADS3 + syntax.
//
//
// DECLARING RECIPES
//
//	A recipe consists of a Recipe instance and then one or more
//	RecipeStep instances (including specialized subclasses, which
//	we'll discuss below).  Here's a very minimalistic recipe
//	declaration:
//
//		+Recipe 'toast' @Toast ->toaster;
//		++Ingredient @Bread;
//		++RecipeAction @toaster ->TurnOnAction;
//
//	Going through that line by line, that's:
//
//		-A Recipe declaration.  It creates a recipe with the
//		 	ID "toast" (the single-quoted string).  When completed
//			the recipe will create an instance of the Toast
//			class (the class name after the @).  The created
//			object will be placed in the toaster object (the
//			object name after the ->).
//
//			In order for this recipe to work, the Toast class
//			and toaster object must be defined elsewhere.
//
//		-An Ingredient declaration.  This says that the recipe requires
//			a Bread object (the class name after the @).  This
//			ingredient declaration doesn't specify a location,
//			so the recipe will expect the ingredient to go into
//			the same location it uses for its results, in this
//			case the toaster.
//
//		-A RecipeAction declaration.  This is an action trigger that
//			fires when the toaster (the object name after the @)
//			receives the TurnOnAction (the action name after
//			the ->).  That is, it will match when the command
//			>TURN ON TOASTER is used.
//
//	With this recipe, the command sequence:
//
//		>PUT BREAD IN TOASTER
//		>TURN TOASTER ON
//
//	...will result in an instance of the Toast class to be placed in
//	the toaster, removing the Bread instance in the process.
//
//	Note, however, that absolutely no other recipe-specific actions will
//	happen and no informational messages will be displayed with this
//	recipe as written.
//
//
// RECIPE ACTIONS
//
//	The example above works but doesn't provide a very good gameplay
//	experience.  To embellish things, let's look at a slightly less
//	barebones version of the toast example:
//
//		+Recipe 'toast' @Toast ->toaster
//			"The toaster produces a slice of toast. ";
//		++RecipeNoAction @toaster ->TurnOnAction
//			"The toaster won't start without bread. ";
//		++IngredientList
//			"{You/He} put{s} the bread in the toaster. ";
//		+++Ingredient @Bread;
//		++RecipeAction @toaster ->TurnOnAction
//			"{You/he} start{s} the toaster. ";
//
//	The first additions to notice are the double-quoted strings after
//	most parts of the recipe.  They will be displayed when the
//	corresponding part of the recipe is completed.  For example, the
//	Recipe declaration:
//
//		+Recipe 'toast' @Toast ->toaster
//			"The toaster produces a slice of toast. ";
//
//	...will display "The toaster produces a slice of toast. " when the
//	recipe is completed.  The format here is a template, and works
//	if you just want to display an informational message.  If you need
//	to do more you can declare a recipeAction() method:
//
//		+Recipe 'toast' @Toast ->toaster
//			recipeAction() {
//				"The toaster produces a slice of toast. ";
//			}
//		;
//
//	This will work exactly the same as the more concise version, but
//	allows arbitrary code to be excuted at the appropriate time.
//
//
//	The expanded version of the recipe also includes a RecipeNoAction
//	declaration:
//
//		++RecipeNoAction @toaster ->TurnOnAction
//			"The toaster won't start without bread. ";
//
//	The format of a RecipeNoAction declaration is the same as
//	RecipeAction declaration, but the "no action" version doesn't
//	change the state of the recipe.  Here it's used to output an
//	informational message.  You could aslo declare a recipeAction()
//	method as above if you wanted.
//
//
//	Next, this version of the recipe includes an explicit IngredientList
//	declaration.  In the simpler version the Ingredient declaration was
//	added directly to the Recipe.
//
//	All Ingredient declarations are added to the "nearest" IngredientList
//	above them.  If no IngredientList exists in the recipe, one is
//	created automatically.
//
//	If you only have one step in the recipe that involves combining
//	ingredients you could get away without an explicit IngredientList
//	declaration.  But if there are multiple "combine a bunch of ingredients"
//	steps you need explicit IngredientLists.
//
//	Having an IngredientList also allows you to attach an informational
//	message and/or a full recipeAction() method, which you CANNOT do
//	on an Ingredient.
//
//
//	Finally, the RecipeAction declaration includes an informational
//	message.  It too could use a recipeAction() method if desired.
//
//
// NOTES
//
//	For single-step recipes, use the IngredientAction class.
//	It has the same syntax as a RecipeAction, but any objects
//	involved in the action which are instaces of CraftingIngredient
//	will be consumed by the action.
//
//		+Recipe 'buttered toast' @ButteredToast;
//		++IngredientAction @Butter @Toast ->PutOnAction
//			"{You/He} butter{s} the toast. ";
//
//	The result of an IngredientAction recipe will end up in the
//	location of the gIobj of the action if one is defined, the gDobj
//	of the action otherwise.
//
#include <adv3.h>
#include <en_us.h>

#include "craftingSystem.h"

// Module ID for the library
craftingSystemModuleID: ModuleID {
        name = 'Crafting System Library'
        byline = 'Diegesis & Mimesis'
        version = '1.0'
        listingOrder = 99
}

// Generic crafting system object.  Mostly for logging.
class CraftingSystemObject: RuleEngineObject
	syslogID = 'CraftingSystem'
	syslogFlag = 'CraftingSystem'
;

// Ownership-agnostic preinit.  Goes through all the various bits of recipes
// and makes sure they're inintialized, but we don't keep track of anything
// in this singleton.
craftingSystemPreinit: PreinitObject
	execute() {
		initializeIngredients();
		initializeRecipeSteps();
		initializeRecipeShortcuts();
		initializeRecipes();
	}

	// Initialize all the ingredients.  These are the declarative
	// statements in recipes, not the in-game objects they refer to.
	initializeIngredients() {
		forEachInstance(Ingredient, function(o) {
			o.initializeIngredient();
		});
	}

	// Initialize the recipe steps.  These are the "operative" bits
	// of the recipe describing actions and transitions.
	initializeRecipeSteps() {
		forEachInstance(RecipeStep, function(o) {
			o.initializeRecipeStep();
		});
	}

	// Initialize the recipes themselves.  These are state machines
	// that track the progress of the recipe they represent.
	initializeRecipes() {
		forEachInstance(Recipe, function(o) {
			o.initializeRecipe();
		});
	}

	initializeRecipeShortcuts() {
		forEachInstance(RecipeShortcut, function(o) {
			o.initializeRecipeShortcut();
		});
	}
;

/*
craftingSystemManager: CraftingSystemObject, BeforeAfterThing, PreinitObject
	syslogID = 'craftingSystemManager'

	_craftingSystemList = perInstance(new Vector())

	_lastLocation = nil

	execute() {
		forEachInstance(CraftingSystem, function(o) {
			_craftingSystemList.append(o);
		});
	}

	// We update after the action, because the only actions we
	// really care about are movement actions (which will change the
	// location)
	globalAfterAction() {
		if(gActor.location == _lastLocation)
			return;
		_lastLocation = gActor.location;

		_craftingSystemList.forEach(function(o) {
			o.checkCraftingLocation();
		});
	}
;
*/

// Base class for crafting systems.  These are collections of recipes.
class CraftingSystem: CraftingSystemObject
	syslogID = 'CraftingSystem'

	// If defined, the recipes in this crafting system are only available
	// in this location.
	craftingLocation = nil

	// A vector of all the recipes we take care of.
	_recipeList = perInstance(new Vector())

	// Add a recipe.
	addRecipe(obj) {
		// Make sure the arg is a Recipe.
		if((obj == nil) || !obj.ofKind(Recipe))
			return(nil);

		// Remember what crafting system the recipe belongs to.
		obj.craftingSystem = self;

		// Add it.
		_recipeList.append(obj);

		return(true);
	}

	// Remove a recipe.
	removeRecipe(obj) {
		// Make sure its in the list.
		if(_recipeList.indexOf(obj) == nil)
			return(nil);

		// Remove it.
		_recipeList.removeElement(obj);

		return(true);
	}

/*
	checkCraftingLocation() {
		aioSay('Checking crafting location\n ');
	}
*/
;
