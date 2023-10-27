#charset "us-ascii"
//
// ingredientTest.t
// Version 1.0
// Copyright 2022 Diegesis & Mimesis
//
// This is a very simple demonstration "game" for the craftingSystem library.
//
// It can be compiled via the included makefile with
//
//	# t3make -f ingredientTest.t3m
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
		syslog.enable('rule');
		showIntro();
		runGame(true);
	}
	showIntro() {
	}
;

class Slice: Thing, CraftingIngredient
	desc = "It's <<aName>>. "
	isEquivalent = true
;

class Bread: Slice '(slice) bread' 'slice of bread';
class Toast: Slice '(slice) toast' 'slice of toast';

startRoom: Room 'Void' "This is a featureless void.";
+me: Person;
++Bread;
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

RuleEngine;

cookingSystem: CraftingSystem;

+Recipe 'toast' @Toast ->toaster "The toaster produces a slice of toast. ";
++Ingredient @Bread;
++RecipeAction @toaster ->TurnOnAction "The toaster heats up. ";
