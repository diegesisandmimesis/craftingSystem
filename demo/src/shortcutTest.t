#charset "us-ascii"
//
// shortcutTest.t
// Version 1.0
// Copyright 2022 Diegesis & Mimesis
//
// This is a very simple demonstration "game" for the craftingSystem library.
//
// It can be compiled via the included makefile with
//
//	# t3make -f shortcutTest.t3m
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

gameMain: GameMainDef
	initialPlayerChar = me
	newGame() {
		syslog.enable('transition');
		showIntro();

		gDebugStateMachines();

		runGame(true);
	}
	showIntro() {
		"This demo extends the toaster demo to include a test
		of IngredientAction.  Specifically the player can now do
		<.p>
		\n\t<b>&gt;PUT BUTTER ON BREAD</b>
		<.p>
		...and (if they've made toast)...
		<.p>
		\n\t<b>&gt;PUT BUTTER ON TOAST</b>
		<.p> ";
	}
;

startRoom: Room 'Void' "This is a featureless void. "
	north = northRoom
;
+toaster: Toaster;

northRoom: Room 'North Room' "This is the north room. "
	south = startRoom
;

+me: Person, CraftingGear;
++Bread;
++Bread;
++Butter;

RuleEngine;

cookingSystem: CraftingSystem;

+Recipe 'toast' @Toast ->toaster
	"The toaster produces a slice of toast. "
	startKnown = true
;
++RecipeShortcut 'toast' 'toast' ->MakeAction
	"{You/He} make{s} some toast. "
	cantCraftRecipeUnknown = '{You/He} do{es}n\'t know how to toast
		bread, amazingly. '
;
++RecipeNoAction @toaster ->TurnOnAction
	"The toaster won't start without bread. ";
++IngredientList
	"{You/He} put{s} the bread in the toaster. ";
+++Ingredient @Bread;
++RecipeAction @toaster ->TurnOnAction
	"{You/he} start{s} the toaster. ";

+Recipe 'buttered toast' @ButteredToast;
++IngredientAction @Butter @Toast ->PutOnAction
	"{You/He} butter{s} the toast. ";

+Recipe 'buttered bread' @ButteredBread;
++IngredientAction @Butter @Bread ->PutOnAction
	"{You/He} butter{s} the bread. ";


DefineCraftingAction(Make);
VerbRule(Make)
	'make' singleDobj : MakeAction
	verbPhrase = 'make/making (what)'
	craftingVerb = 'make'
;
