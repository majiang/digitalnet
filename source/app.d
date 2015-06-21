import std.stdio;
import std.algorithm : reduce, min, setIntersection;
import std.typecons : Flag;

import digitalnet.implementation, digitalnet.integration;

void main()
{
	auto digitalnet = randomDigitalNet!uint(Precision(32), DimensionR(4), DimensionF2(4));
	digitalnet.integral((real[] x) => x.reduce!min).writeln;
	auto neighbor = digitalnet.changeVectorOfBasis;
	import std.algorithm : sort;
	import std.array : array;
	uint[][] p, q;
	foreach (x; digitalnet)
		p ~= x.dup;
	foreach (x; neighbor)
		q ~= x.dup;
	writeln(p.length, ": ", p);
	writeln(q.length, ": ", q);
	writeln(p.sort().setIntersection(q.sort()).array.length);
}
