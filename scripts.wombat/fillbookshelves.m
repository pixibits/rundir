inherits furniture;

function int Q4JX(obj Q4E2) {
	if (containedBy(Q4E2) != NULL()) {
		return(0x01);
	}
	if (!thinksItsAtHome(this)) {
		return(0x01);
	}
	int i;
	int Q56F;
	int Q5E7;
	int Q55X = 0x02;
	list Q4E5;
	list Q5JX = 0x0FEF, 0x0FF0;
	obj Q4Q1;
	getContents(Q4E5, Q4E2);
	if (numInList(Q5JX) < 0x01) {
		return(0x00);
	}
	if (numInList(Q4E5) <= Q55X) {
		Q56F = random(0x00, ((Q55X - numInList(Q4E5)) + 0x01) * 0x02);
		if (Q56F > 0x04) {
			Q56F = 0x04;
		}
		for (i = 0x00; i < Q56F; i++) {
			Q5E7 = random(0x00, numInList(Q5JX) - 0x01);
			Q4Q1 = requestCreateObjectIn(Q5JX[Q5E7], Q4E2);
		}
	}
	return(0x00);
}

trigger decay {
	list contents;
	getContents(contents, this);
	if (numInList(contents) <= 0x02) {
		if (!hasObjVar(this, "filled")) {
			Q4JX(this);
			setObjVar(this, "filled", 0x01);
		} else if (!hasCallback(this, 0x50)) {
			callback(this, random(0x0E10, 0x1518), 0x50);
		}
	}
	return(0x01);
}

trigger callback(0x50) {
	removeObjVar(this, "filled");
	return(0x00);
}
