#charset "us-ascii"
//
// kitchenWorld.t
//
//	A simple environment for testing recipes.
//
#include <adv3.h>
#include <en_us.h>

#include "craftingSystem.h"

class Slice: Thing, Surface, CraftingIngredient
	desc = "It's <<aName>>. "
	isEquivalent = true
;

class Bread: Slice '(slice) bread' 'slice of bread';
class Toast: Slice, Craftable '(slice) toast' 'slice of toast';
class ButteredBread: Bread, Craftable '(buttered) (slice) bread' 'slice of buttered bread';
class ButteredToast: Toast, Craftable '(buttered) (slice) toast' 'slice of buttered toast';

class Butter: CraftingIngredient '(pat) butter' 'pat of butter'
	"It's <<aName>>. "
	isEquivalent = true
;

class Toaster: Container, CraftingGear '(silver) (metal) toaster slot' 'toaster'
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
