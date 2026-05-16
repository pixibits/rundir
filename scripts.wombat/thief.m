trigger creation {
	int Q4AY = random(0x01, 0x05);
	if (Q4AY == 0x01) {
		addFragment(this, "Britannia_Actor");
		return(0x00);
	}
	if (Q4AY == 0x02) {
		addFragment(this, "Britannia_Beggar");
		return(0x00);
	}
	if (Q4AY == 0x03) {
		addFragment(this, "Britannia_Gypsy");
		return(0x00);
	}
	if (Q4AY == 0x04) {
		addFragment(this, "Britannia_Artist");
		return(0x00);
	}
	if (Q4AY == 0x05) {
		addFragment(this, "Britannia_Laborer");
		return(0x00);
	}
	return(0x00);
}

trigger acquiredesire {
	int Q5IR;
	obj thief;
	if (isPlayer(target)) {
		if (hasObjVar(target, "guildMember")) {
			Q5IR = getObjVar(target, "guildMember");
		}
		if (Q5IR == 0x03) {
			return(0x01);
		} else {
			int Q5IQ = getMoney(target);
			int Q4PL = Q5IQ / 0x14;
			thief = transferGenericToContainer(this, target, 0x0EED, Q4PL);
			barkTo(this, target, "pilfered");
			stopFollowing(this);
			runAway(this, target);
			setCriminal(this, 0x01E0);
		}
	}
	return(0x01);
}
