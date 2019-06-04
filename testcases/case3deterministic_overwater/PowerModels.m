function mpc = case3
% CASE3 Power flow data for 3 bus, 3 gen case
% This case borrowed from the paper
% "Assessing the Cost of Time-Inconsistent Operation Policies in Hydrothermal Power Systems"
% Adapted by Andrew Rosemberg
% Electrical Department
% PUC-Rio - Pontifical Catholic University of Rio de Janeiro
% Rio de Janeiro, RJ, BRS

%% MATPOWER Case Format : Version 2
mpc.version = '2';

%%-----  Power Flow Data  -----%%
%% system MVA base
mpc.baseMVA = 100;

%% bus data
%	bus_i	type	Pd	Qd	Gs	Bs	area	Vm		Va	baseKV	zone	Vmax	Vmin
mpc.bus = [
	1		3		0   0   0	0	1		1.00	0   0		1		1.1     0.9;
	2		2		0   0   0	0	1		1.00	0   0		1		1.1     0.9;
	3		2		100	0  	0	0	1		1.00	0   0		1		1.1     0.9;
];

%% generator data
%	bus	Pg	Qg	Qmax	Qmin	Vg		mBase	status	Pmax	Pmin	Pc1	Pc2	Qc1min	Qc1max	Qc2min	Qc2max	ramp_agc	ramp_10	ramp_30	ramp_q	apf
mpc.gen = [
	2	0	0	10000	-10000	1.00	100		1		100   	0		0	0	0	0	0	0	0	0	0	0	0;
	3	0   0	10000	-10000	1.00	100		1		50   	0		0	0	0	0	0	0	0	0	0	0	0;
	1	0   0	10000	-10000	1.00	100		1		80   	0  		0	0	0	0	0	0	0	0	0	0	0;
];

%% branch data
%	fbus	tbus	r		x		b		rateA	rateB	rateC	ratio	angle	status	angmin	angmax
mpc.branch = [
	1		3		0.065	1.00	0.450	100		0		0		0       0		1		-360	360;
	3		2		0.025	0.50	0.700	65      0		0		0       0		1		-360	360;
	1		2		0.042	1.00	0.300	25		0		0		0       0		1		-360	360;
];

%%-----  OPF Data  -----%%
%% generator cost data
%	1	startup	shutdown	n	x1	y1	...	xn	yn
%	2	startup	shutdown	n	c(n-1)	...	c0
mpc.gencost = [
	2	0	0	2 20 	0;
	2	0	0	2 100 	0;
	2	0	0	2 0 	0;
];
