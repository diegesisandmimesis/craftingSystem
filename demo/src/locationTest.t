#charset "us-ascii"
//
// locationTest.t
// Version 1.0
// Copyright 2022 Diegesis & Mimesis
//
// This is a very simple demonstration "game" for the craftingSystem library.
//
// It can be compiled via the included makefile with
//
//	# t3make -f locationTest.t3m
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
#include "linter.h"

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

/*
// Hack to enable preinit debugging when compiled with -D SYSLOG
modify syslog
	_flag = static [
		'rulebook' -> true,
		'rule' -> true,
		'ruleuser' -> true
	]
;
*/

gameMain: GameMainDef
	initialPlayerChar = me
	newGame() {
		//syslog.enable('transition');
		showIntro();
		runGame(true);
	}
	showIntro() {
		"This is equivalent to the test in toaster.t, but using
		a location-based rule scheduler.
		<.p> ";
	}
;

startRoom: Room 'Void'
	"This is a featureless void.  The kitchen is north of here. "
	north = kitchen
;
+me: Person, CraftingGear;
++Bread;
++Bread;
++Butter;

kitchen: CraftingRoom 'Kitchen'
	"This is a featureless kitchen.  The void lies to the south. "
	south = startRoom
;
+toaster: RuleScheduler, Toaster;
//+toaster: Toaster, RuleScheduler;

cookingSystem: CraftingSystem
	craftingLocation = kitchen
;

+Recipe 'toast' @Toast ->toaster
	"The toaster produces a slice of toast. "
	craftingLocation = toaster
;
++RecipeNoAction @toaster ->TurnOnAction
	"The toaster won't start without bread. ";
++IngredientList
	"{You/He} put{s} the bread in the toaster. ";
+++Ingredient @Bread;
++RecipeAction @toaster ->TurnOnAction
	"{You/he} start{s} the toaster. ";
