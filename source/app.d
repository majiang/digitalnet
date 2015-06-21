import std.stdio;
import std.algorithm : reduce, min;
import std.typecons : Flag;

import digitalnet.implementation, digitalnet.integration;

void main()
{
	auto digitalnet = randomDigitalNet!uint(Precision(32), DimensionR(4), DimensionF2(4));
	digitalnet.integral((real[] x) => x.reduce!min).writeln;
	auto shuffled = digitalnet.shuffle;
	import std.algorithm : sort;
	import std.array : array;
	uint[][] p, q;
	foreach (x; digitalnet)
		p ~= x.dup;
	foreach (x; shuffled)
		q ~= x.dup;
	sort(p);
	sort(q);
	writeln(p);
	writeln(q);
	assert (p == q);
}
