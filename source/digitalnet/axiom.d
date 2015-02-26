module digitalnet.axiom;

import std.range, std.traits;

enum isPointSet(S) = isInputRange!S && isArray!(ElementType!S) && isUnsigned!(ElementType!(ElementType!S));

enum hasPrecision(S) = is (size_t == Unqual!(typeof (__traits (getMember, S, "precision"))));

enum hasDimensionR(S) = hasMember!(S, "dimensionR");

enum hasDimensionF2(S) = hasMember!(S, "dimensionF2");

enum bisectable(S) = is (typeof (
{
	S P;
	if (P.bisectable)
		S[2] Q = P.bisect;
}));
