module digitalnet.integration;

import digitalnet.axiom;
import std.traits, std.math;
import std.range : ElementType;
import std.typecons : Flag;
alias Centering = Flag!"centering";

auto _integral(Centering centering=Centering.yes, S, Function)(S P, Function f)
	if (isPointSet!S && hasPrecision!S && hasDimensionR!S &&
		isArray!(ParameterTypeTuple!Function) && isFloatingPoint!(ElementType!(ParameterTypeTuple!Function)))
{
	pragma(msg, "_integral!(", typeid(S), ", ", typeid(Function), ")");
	alias F = ElementType!(ParameterTypeTuple!Function);
	F result = 0;
	foreach (x; P.toReals!(F, centering, S))
		result += f(x);
	return result * exp2(-cast(ptrdiff_t)P.dimensionF2);
}

auto integral(Centering centering=Centering.yes, S, Function)(S P, Function f)
	if (isPointSet!S && hasPrecision!S && hasDimensionR!S
	 && isArray!(ParameterTypeTuple!Function) && isFloatingPoint!(ElementType!(ParameterTypeTuple!Function))
	 && !(isBisectable!S))
{
	pragma(msg, "integralNonbisectable!(", typeid(S), ", ", typeid(Function), ")");
	return _integral!(centering, S, Function)(P, f);
}

auto integral(Centering centering=Centering.yes, S, Function)(S P, Function f)
	if (isPointSet!S && hasPrecision!S && hasDimensionR!S
	 && isArray!(ParameterTypeTuple!Function) && isFloatingPoint!(ElementType!(ParameterTypeTuple!Function))
	 && (isBisectable!S))
{
	pragma(msg, "integralBisectable!(", typeid(S), ", ", typeid(Function), ")");
	if (!P.bisectable)
		return _integral!(centering, S, Function)(P, f);
	auto Q = P.bisect;
	return (integral!(centering, S, Function)(Q[0], f) +
	        integral!(centering, S, Function)(Q[1], f)) / 2;
}

auto toReals(F, Centering centering=Centering.yes, S)(S P)
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
