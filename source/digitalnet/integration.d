module digitalnet.integration;

import digitalnet.axiom;
import std.traits, std.math;
import std.range : ElementType;
import std.typecons : Flag;

auto integral(Flag!"centering" centering=Flag!"centering".yes, S, Function)(S P, Function f)
	if (isPointSet!S && hasPrecision!S && hasDimensionR!S &&
		isArray!(ParameterTypeTuple!Function) && isFloatingPoint!(ElementType!(ParameterTypeTuple!Function)))
{
	alias F = ElementType!(ParameterTypeTuple!Function);
	F result = 0;
	foreach (x; P.toReals!(F, centering, S))
		result += f(x);
	return result * exp2(-cast(ptrdiff_t)P.dimensionF2);
}

auto toReals(F, Flag!"centering" centering=Flag!"centering".yes, S)(S P)
	if (isFloatingPoint!F && isPointSet!S && hasPrecision!S && hasDimensionR!S)
{
	struct R
	{
		static if (centering)
			enum F h = 0.5;
		else
			enum F h = 0;
		immutable F f;
		S P;
		alias P this;
		F[] front;
		void popFront()
		{
			P.popFront;
			if (empty)
				return;
			foreach (i, ref e; front)
				e = (P.front[i] + h) * f;
		}
		this (S P)
		{
			f = exp2(-cast(ptrdiff_t)P.precision);
			this.P = P;
			front.length = P.dimensionR;
			foreach (i, ref e; front)
				e = (P.front[i] + h) * f;
		}
	}
	return R(P);
}
