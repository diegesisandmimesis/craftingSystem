#charset "us-ascii"
//
// sample.t
// Version 1.0
// Copyright 2022 Diegesis & Mimesis
//
// This is a very simple demonstration "game" for the craftingSystem library.
//
// It can be compiled via the included makefile with
//
//	# t3make -f makefile.t3m
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
		syslog.enable('Recipe');
		syslog.enable('ruleEngine');
		syslog.enable('RuleEngine');
		syslog.enable('RuleEngineMatches');

		syslog.enable('StateMachine');

		runGame(true);
	}
;

class Bread: Thing, CraftingIngredient
	'(slice) bread' 'slice of bread'
	"It's a slice of bread. "
	isEquivalent = true
;

class Toast: Bread, CraftingIngredient
	'(slice) toast' 'slice of toast'
	"It's a slice of toast. "
	isEquivalent = true
;

class ButteredToast: Thing, CraftingIngredient
	'(slice) (buttered) toast' 'slice of buttered toast'
	"A slice of buttered toast. "
	isEquivalent = true
;

startRoom: Room 'Void' "This is a featureless void.";
+me: Person;
++Bread;
+toaster: Container, CraftingGear '(silver) (metal) toaster slot' 'toaster'
	"A silver toaster with a slot on the top. "
	dobjFor(TurnOn) {
		verify() {}
	}
	canFitObjThruOpening(obj) { return(obj.ofKind(Bread)); }
;
+butter: Thing, CraftingGear
	'(stick) butter' 'stick of butter'
	"A stick of butter. "
;

myRuleEngine: RuleEngine;

cookingSystem: CraftingSystem;

// Recipe declaration.
// First arg is the ID.
// Second is what it produces.
// Third is where it will be produced.
//+Recipe 'toast' @Toast ->(toaster.location);
+Recipe 'toast' @Toast ->toaster;
++RecipeAction @Bread @toaster ->PutInAction
	"{You/he} put{s} <<gDobj.theName>> in the toaster. "
;
++RecipeAction @toaster ->TurnOnAction
	recipeAction() {
		"The toaster produces a slice of toast. ";
	}
;

+Recipe 'buttered toast' @ButteredToast;
++RecipeAction @butter @Toast ->PutOnAction;
