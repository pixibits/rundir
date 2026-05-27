inherits globals;

function int Q4JZ(obj user) {
	barkTo(user, user, "This doesn't belong to me, I'll have to steal it.");
	return(0x00);
}

trigger objaccess(0x04) {
	return(Q4JZ(user));
}

trigger objaccess(0x05) {
	return(Q4JZ(user));
}
