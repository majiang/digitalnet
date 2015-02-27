import std.stdio;

import digitalnet.implementation, digitalnet.integration;

auto toArray(R)(R r)
{
	import std.range, std.array;
	alias T = ElementType!R;
	T[] ret;
	foreach (x; r)
		ret ~= x.dup;
	return ret;
}

void main()
{
	auto
		s = readln,
		P = s.toShiftedDigitalNet!uint,
		Q = s.toShiftedDigitalNet!uint.toReals!real,
		R = s.toShiftedDigitalNet!uint.toReals!(real, Centering.no);
	writefln("uints:\n%(%(%d %)\n%)", P.toArray);
	writefln("reals:\n%(%(%f %)\n%)", Q.toArray);
	writefln("reals (without centering):\n%(%(%f %)\n%)", R.toArray);
}
