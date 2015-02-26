import std.stdio, std.conv;
import digitalnet.implementation;

void main(string[] args)
{
	if (args.length < 5)
	{
		stderr.writeln("generate dimensionR dimensionF2 precision count");
		return;
	}
	auto
		dimR = DimensionR(args[1].to!size_t),
		dimB = DimensionF2(args[2].to!size_t),
		prec = Precision(args[3].to!size_t),
		count = args[4].to!size_t;
	foreach (i; 0..count)
		randomDigitalNet(prec, dimR, dimB).writeln;
}
