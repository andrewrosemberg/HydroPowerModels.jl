function mpc = case3Lesieutre
% This case borrowed from the paper
% "Examining the Limits of the Application of Semidefinite Programming to Power Flow Problems"
% by Bernard C. Lesieutre, Daniel K. Molzahn, Alex R. Borden, and Christopher L. DeMarco
% Electrical and Computer Engineering Department
% University of Wisconsin-Madison
% Madison, WI 53706, USA

%% MATPOWER Case Format : Version 2
mpc.version = '2';

%%-----  Power Flow Data  -----%%
%% system MVA base
mpc.baseMVA = 100;

%% bus data
%	bus_i	type	Pd	Qd	Gs	Bs	area	Vm	Va	baseKV	zone	Vmax	Vmin
mpc.bus = [
	1	3	110     40   0	0	1	1.00	0       0	1	1.1     0.9;
	2	2	110     40   0	0	1	1.00	0       0	1	1.1     0.9;
	3	2	95      50   0	0	1	1.00	0       0	1	1.1     0.9;
];

%% generator data
%	bus	Pg	Qg	Qmax	Qmin	Vg	mBase	status	Pmax	Pmin	Pc1	Pc2	Qc1min	Qc1max	Qc2min	Qc2max	ramp_agc	ramp_10	ramp_30	ramp_q	apf
mpc.gen = [
	1	0	0	10000	-10000	1.00	100	1	10000    -10000	0	0	0	0	0	0	0	0	0	0	0;
	2	0   0	10000	-10000	1.00	100	1	10000    -10000	0	0	0	0	0	0	0	0	0	0	0;
	3	0   0	10000	-10000	1.00	100	1	0       0       0	0	0	0	0	0	0	0	0	0	0;
];

%% branch data
%	fbus	tbus	r	x	b	rateA	rateB	rateC	ratio	angle	status	angmin	angmax
mpc.branch = [
	1	3	0.065	0.620	0.450	9900	0	0	0       0	1	-360	360;
	3	2	0.025	0.750	0.700	50      0	0	0       0	1	-360	360;
	1	2	0.042	0.900	0.300	9900	0	0	0       0	1	-360	360;
];

%%-----  OPF Data  -----%%
%% generator cost data
%	1	startup	shutdown	n	x1	y1	...	xn	yn
%	2	startup	shutdown	n	c(n-1)	...	c0
mpc.gencost = [
	2	0	0	3	0.11	5	0;
	2	0	0	3	0.085   1.2	0;
	2	0	0	3	0       0	0;
];
