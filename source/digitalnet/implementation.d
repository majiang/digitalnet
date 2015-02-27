module digitalnet.implementation;

import digitalnet.axiom;
import std.traits, std.algorithm, std.array, std.range, std.typecons, std.random, std.exception, std.string;
import std.conv : to;
debug import std.stdio;

static assert (isPointSet!(DigitalNet!uint));
static assert (hasPrecision!(DigitalNet!uint));
static assert (isPointSet!(ShiftedDigitalNet!uint));
static assert (hasPrecision!(ShiftedDigitalNet!uint));

mixin template DigitalNetFunctions(U, Size)
{
	const U[][] basis;
	immutable size_t precision, dimensionF2, dimensionR;
	this (in U[][] basis, Precision precision = Precision(U.sizeof << 3))
	{
		this.basis = basis;
		this.precision = precision.getPrecision;
		this.dimensionF2 = basis.length;
		this.dimensionF2.enforce("Zero digital net is not constructible");
		this.dimensionR = basis[0].length;
		foreach (b; basis)
			assert (b.length == dimensionR);
		this.front = new U[dimensionR];
	}
	bool empty;
	U[] front;
	void popFront()
	in
	{
		assert (!empty);
	}
	body
	{
		position += 1;
		if (position >> dimensionF2)
		{
			empty = true;
			return;
		}
		front[] ^= basis[position.bottom_zeros][];
	}
	private Size position;
	string _toString()
	{
		return "%d %d %d %(%(%d %) %)".format(precision, dimensionF2, dimensionR, basis);
	}
}

/// A digital net.
struct DigitalNet(U = uint, Size = GreaterInteger!U)
	if (isUnsigned!U)
{
	mixin DigitalNetFunctions!(U, Size);
	ShiftedDigitalNet!(U, Size) opBinary(string op)(in U[] shift) const
		if (op == "+")
	{
		return ShiftedDigitalNet!(U, Size)(basis, shift, Precision(precision));
	}
	DigitalNet!(U, Size) removeShift()
	{
		return this;
	}
	alias toString = _toString;
}

/// A digitally shifted digital net.
struct ShiftedDigitalNet(U = uint, Size = GreaterInteger!U)
	if (isUnsigned!U)
{
	immutable bool bisectable;
	mixin DigitalNetFunctions!(U, Size);
	const U[] shift;
	this (in U[][] basis, Precision precision = Precision(U.sizeof << 3))
	{
		this.basis = basis;
		this.precision = precision.getPrecision;
		this.dimensionF2 = basis.length;
		this.dimensionF2.enforce("Zero digital net is not constructible");
		this.dimensionR = basis[0].length;
		foreach (b; basis)
			assert (b.length == dimensionR);
		this.front = new U[dimensionR];
	}
	this (in U[][] basis, in U[] shift, Precision precision = Precision(U.sizeof << 3))
	{
		this (basis, precision);
		this.bisectable = bisectThreshold <= this.dimensionF2;
		this.shift = shift;
		this.front[] = shift[];
	}
	ShiftedDigitalNet!(U, Size) opBinary(string op)(in U[] shift) const
		if (op == "+")
	{
		auto newShift = new U[dimensionR];
		foreach (i, ref s; newShift)
			s = this.shift[i] ^ shift[i];
		return ShiftedDigitalNet!(U, Size)(basis, newShift, Precision(precision));
	}
	DigitalNet!(U, Size) removeShift() const
	{
		return DigitalNet!(U, Size)(basis, Precision(precision));
	}
	ShiftedDigitalNet!(U, Size)[2] bisect() const
	{
		auto former = ShiftedDigitalNet!(U, Size)(this.basis[1..$], this.shift, Precision(this.precision));
		return [former, former + this.basis[0]];
	}
	string toString()
	{
		return _toString() ~ " %(%d %)".format(shift);
	}
}

/// read a digital net from a string.
DigitalNet!U toDigitalNet(U = uint)(const(char)[] x)
{
	auto
		buf = x.strip.split(',')[0].split,
		prec = buf[0].to!size_t,
		dimB = buf[1].to!size_t,
		dimR = buf[2].to!size_t;
	buf = buf[3..$];
	enforce(buf.length == dimB * dimR || buf.length == (dimB + 1) * dimR);
	if (buf.length == (dimB + 1) * dimR)
	{
		import std.stdio;
		stderr.writefln("run-time warning: ignoring shift [%(%s %)]", buf[dimB * dimR .. $]);
		buf = buf[0 .. dimB * dimR];
	}
	auto basis = buf.map!(to!U).array.chunks(dimR).array;
	return DigitalNet!U(basis, Precision(prec));
}

ShiftedDigitalNet!U toShiftedDigitalNet(U = uint)(const(char)[] x)
{
	auto
		buf = x.strip.split(',')[0].split,
		prec = buf[0].to!size_t,
		dimB = buf[1].to!size_t,
		dimR = buf[2].to!size_t;
	buf = buf[3..$];
	enforce(buf.length == (dimB + 1) * dimR || buf.length == dimB * dimR);
	auto basis = buf.map!(to!U).array.chunks(dimR).array;
	U[] shift;
	if (buf.length == dimB * dimR)
	{
		import std.stdio;
		stderr.writeln("run-time warning: add a zero shift");
		shift = new U[dimR];
	}
	else
	{
		shift = basis[$ - 1];
		basis = basis[0 .. $ - 1];
	}
	return ShiftedDigitalNet!U(basis, shift, Precision(prec));
}

template GreaterInteger(U)
	if (isUnsigned!U)
{
	import std.bigint;
	static if (U.sizeof < ulong.sizeof)
		alias GreaterInteger = ulong;
	else
		alias GreaterInteger = BigInt;
}

immutable size_t getPrecision(Precision n)
{
	return cast(size_t)n;
}
immutable size_t getDimensionR(DimensionR s)
{
	return cast(size_t)s;
}
immutable size_t getDimensionF2(DimensionF2 m)
{
	return cast(size_t)m;
}

alias Precision = Typedef!(size_t, 0, "prec");

alias DimensionR = Typedef!(size_t, 0, "dimR");

alias DimensionF2 = Typedef!(size_t, 0, "dimB");

DigitalNet!U randomDigitalNet(U = uint)(Precision precision, DimensionR dimensionR, DimensionF2 dimensionF2)
	if (isUnsigned!U)
{
	immutable s = dimensionR.getDimensionR;
	auto basis = randomVector!U(precision.getPrecision, s * dimensionF2.getDimensionF2).chunks(s).array;
	return DigitalNet!U(basis, precision);
}

U[] randomDigitalShift(U, Size)(DigitalNet!(U, Size) P)
{
	return randomVector!U(P.precision, P.dimensionR);
}
U[] randomDigitalShift(U, Size)(ShiftedDigitalNet!(U, Size) P)
{
	return randomVector!U(P.precision, P.dimensionR);
}

U[] randomDigitalShift(U)(Precision precision, DimensionR dimensionR)
	if (isUnsigned!U)
{
	return randomVector!U(precision.getPrecision, dimensionR.getDimensionR);
}

private:

U[] randomVector(U)(size_t precision, size_t length)
	if (isUnsigned!U)
{
	auto ret = new U[length];
	randomVector(precision, ret);
	return ret;
}

void randomVector(U)(size_t precision, U[] buffer)
{
	randomVector(buffer);
	if (auto d = (U.sizeof << 3) - precision)
		foreach (ref e; buffer)
			e >>= d;
}

void randomVector(U)(U[] buffer)
{
	foreach (ref e; buffer)
		e = uniform!U;
}

auto bottom_zeros(Size)(Size x)
{
	assert (x);
	size_t ret;
	while ((x & 1) == 0)
	{
		x >>= 1;
		ret += 1;
	}
	return ret;
}

enum size_t bisectThreshold = 10;
