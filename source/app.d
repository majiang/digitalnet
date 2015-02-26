import std.stdio;
import std.algorithm : reduce, min;
import std.typecons : Flag;

import digitalnet.implementation, digitalnet.integration;

void main()
{
	randomDigitalNet!uint(Precision(32), DimensionR(4), DimensionF2(4)).integral((real[] x) => x.reduce!min).writeln;
}
