#charset "us-ascii"
//
// toaster.t
// Version 1.0
// Copyright 2022 Diegesis & Mimesis
//
// This is a very simple demonstration "game" for the craftingSystem library.
//
// It can be compiled via the included makefile with
//
//	# t3make -f toaster.t3m
//
// ...or the equivalent, depending on what TADS development environment
// you're using.
//
// This "game" is distributed under the MIT License, see LICENSE.txt
// for details.
//
#include <adv3.h>
#include <en_us.h>

#include "craftingSystem.h"

versionInfo: GameID
        name = 'craftingSystem Library Demo Game'
        byline = 'Diegesis & Mimesis'
        desc = 'Demo game for the craftingSystem library. '
        version = '1.0'
        IFID = '12345'
	showAbout() {
		"This is a simple test game that demonstrates the features
		of the craftingSystem library.
		<.p>
		Consult the README.txt document distributed with the library
		source for a quick summary of how to use the library in your
		own games.
		<.p>
		The library source is also extensively commented in a way
		intended to make it as readable as possible. ";
	}
;

// Hack to enable preinit debugging when compiled with -D SYSLOG
modify syslog
	_flag = static [
		'rulebook' -> true,
		'rule' -> true,
		'ruleuser' -> true
	]
;

gameMain: GameMainDef
	initialPlayerChar = me
	newGame() {
		syslog.enable('transition');
		showIntro();

		gDebugStateMachines();

		runGame(true);
	}
	showIntro() {
	}
;

class Slice: Thing, Surface, CraftingIngredient
	desc = "It's <<aName>>. "
	isEquivalent = true
;

class Bread: Slice '(slice) bread' 'slice of bread';
class Toast: Slice '(slice) toast' 'slice of toast';
class ButteredBread: Bread '(buttered) (slice) bread' 'slice of buttered bread';
class ButteredToast: Toast '(buttered) (slice) toast' 'slice of buttered toast';

class Butter: CraftingIngredient '(pat) butter' 'pat of butter'
	"It's <<aName>>. "
	isEquivalent = true
;

startRoom: Room 'Void' "This is a featureless void.";
+toaster: Container, CraftingGear '(silver) (metal) toaster slot' 'toaster'
	"A silver toaster with a single slot on the top. "
	dobjFor(TurnOn) { verify() {} }
	iobjFor(PutIn) {
		verify() {
			if(contents.length != 0)
				illogicalNow('The toaster can only hold one
					thing at a time. ');
		}
	}
	canFitObjThruOpening(obj) { return(obj.ofKind(Slice)); }
;

+me: Person, CraftingGear;
++Bread;
++Bread;
++Butter;

RuleEngine;

cookingSystem: CraftingSystem;

/*
 * Barebones version of the recipe.
 * Not really usable (from a gameplay perspective) but provided to
 * illustrate the basic moving parts.
 *
+Recipe 'toast' @Toast ->toaster;
++Ingredient @Bread;
++RecipeAction @toaster ->TurnOnAction;
*/

+Recipe 'toast' @Toast ->toaster "The toaster produces a slice of toast. ";
++RecipeNoAction @toaster ->TurnOnAction
	"The toaster won't start without bread. ";
++IngredientList "{You/He} put{s} the bread in the toaster. ";
+++Ingredient @Bread;
++RecipeAction @toaster ->TurnOnAction "{You/he} start{s} the toaster. ";

/*
+Recipe 'buttered toast' @ButteredToast;
++RecipeAction @Butter @Toast ->PutOnAction
	recipeAction() {
		local obj;

		obj = new ButteredToast();
		obj.moveInto(gIobj.location);
		gDobj.moveInto(nil);
		gIobj.moveInto(nil);
		"{You/He} butter{s} the toast. ";
	}
;
*/
+Recipe 'buttered toast' @ButteredToast;
++IngredientSwap @Butter @Toast ->PutOnAction
	"{You/He} butter{s} the toast. ";

+Recipe 'buttered bread' @ButteredBread;
++IngredientSwap @Butter @Bread ->PutOnAction
	"{You/He} butter{s} the bread. ";
