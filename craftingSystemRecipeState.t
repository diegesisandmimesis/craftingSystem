#charset "us-ascii"
//
// craftingSystemRecipeState.t
//
//	The StateMachine-specific crafting system classes.
//
#include <adv3.h>
#include <en_us.h>

#include "craftingSystem.h"

// Recipe-specific subclass of State.
class RecipeState: State, CraftingSystemObject
	syslogID = 'RecipeState'
	syslogFlag = 'RecipeState'

	// We set this flag so the RuleEngine instance doesn't try to
	// initialize us.  All RecipeState instances are created dynamically
	// at preinit, so we take care of initialization ourself.
	_ruleEngineInitFlag = true

	// Property to remember which recipe we're part of.
	recipe = nil
;

class RecipeStepTransition: Transition, CraftingSystemObject
	recipeStep = nil

	// Recipe-specific action called during a transition.
	// By default we just call whatever's defined on the RecipeStep
	// instance that created us.
	recipeAction() { recipeStep._recipeAction(); }

/*
	tryCheck(type?) {
		if(recipe.checkRecipeLocation() != true)
			return(nil);
		return(inherited(type));
	}
*/
;

// Recipe-specific Transition subclass.
class RecipeTransition: RecipeStepTransition
	syslogID = 'RecipeTransition'
	syslogFlag = 'RecipeTransition'

	// The RecipeStep instance that created us.
	recipeStep = nil

	// Make sure the RuleEngine instance doesn't try to initialize us.
	_ruleEngineInitFlag = true

	// Recipe-specific transition action.
	transitionAction() {
		consumeIngredients();
		recipeAction();
	}

	// By default we do not consume our ingredients, but subclasses
	// can overwrite this if they want to (e.g., for recipes where
	// adding an ingredient would be destructive, like cracking an egg
	// into a bowl).
	consumeIngredients() {}
;

// "No transition" transition.  Mostly so we can display informational messages.
class RecipeNoTransition: RecipeStepTransition, NoTransition
	// We never consume any ingredients.
	transitionAction() { recipeAction(); }
;

class RecipeTransitionIrreversible: RecipeTransition
	consumeIngredients() { inherited(); recipeStep.consumeIngredients(); }
;

// Special Transition class for finishing the recipe.
// We consume any ingredients used in the recipe and then produce whatever
// the recipe produces.
class RecipeEnd: RecipeTransition
	// Consume all the ingredients in the recipe.
	consumeIngredients() { inherited(); recipe.consumeIngredients(); }

	// Produce whatever the recipe produces.
	afterTransition() { recipe.produceResult(); }
;

class RecipeIrreversibleEnd: RecipeTransitionIrreversible, RecipeEnd;
