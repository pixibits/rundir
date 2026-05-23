inherits globals;

trigger use {
	int Q645 = getTrammelPhase();
	int Q4OZ = getFeluccaPhase();
	string Q5X4 = getMoonPhaseStr(Q645);
	string Q5WO = getMoonPhaseStr(Q4OZ);
	superBark(user, Q5X4 + " " + Q5WO, 0xFFFFFFFF, 0x08, 0x00);
	return(0x00);
}
