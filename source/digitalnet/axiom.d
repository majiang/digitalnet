module digitalnet.axiom;

import std.range, std.traits;

/// Test if S is a point set.
enum isPointSet(S) = isInputRange!S && isArray!(ElementType!S) && isUnsigned!(ElementType!(ElementType!S));

/// Test if S has a precision parameter.
enum hasPrecision(S) = is (size_t == Unqual!(typeof (__traits (getMember, S, "precision"))));

/// Test if S has a dimension (over R) parameter.
enum hasDimensionR(S) = hasMember!(S, "dimensionR");

/// Test if S has a dimension (over F_2) parameter.
enum hasDimensionF2(S) = hasMember!(S, "dimensionF2");

/// Test if S is bisectable.
enum isBisectable(S) = is (typeof (
{
	S P;
	if (P.bisectable)
		S[2] Q = P.bisect;
}));
