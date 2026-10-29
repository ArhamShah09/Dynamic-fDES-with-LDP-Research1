% SELF_TEST Validate the five feature functions without requiring any dataset.

clear; clc;
addpath(genpath(fullfile(fileparts(mfilename('fullpath')), 'functions')));
C = config();

constant = [800 800 800 800 800];
assert(tDES(constant, 12) == 1);
assert(tri_fDES(constant, 12) == 1);
assert(exp_fDES(constant, 25) == 1);
assert(symDES(constant, 10, C.symbolRangeMs) == 1);
assert(pNN50(constant) == 0);

ramp = [800 810 820 830 840];
assert(tDES(ramp, 5) == 0);
assert(tri_fDES(ramp, 20) > 0 && tri_fDES(ramp, 20) < 1);
assert(exp_fDES(ramp, 25) > 0 && exp_fDES(ramp, 25) < 1);

fprintf('All feature-function sanity tests passed.\n');
