

% DDP implemenation to design the optimal operating policy for Folsom
% (adapted from M3O toolbox)


clear all;
clc

%cd('/Users/matteo/Poli/research/myCode/GIT/ptreeopt/DP_matlab')
global sys_param;

addpath('sim')
addpath('DDP')

%% Set general system parameters

qq  = load('./data/inflow_17.txt','-ascii') ; % 01/10/1904 - 30/09/2015
ee1  = load('./data/evaporation.txt','-ascii') ; % 01/10/1904 - 30/09/2015
ee  = ee1(1:36525);
w   = load('./data/demand.txt','-ascii') ;
%qe2016 = load('./data/data2016.txt','-ascii') ; % 1/10/2015 - 30/09/2016

dn = datenum(2000,1,1):datenum(2099,12,31);
dn_sim = datenum(2080,1,1):datenum(2099,12,31); % simulation horizon 01/1/2000 - 31/12/2099
id1 = find( dn == dn_sim(1) );
id2 = find( dn == dn_sim(end) );
qqs = qq(id1:id2);
% remove 29/feb
dv = datevec(dn_sim');
feb29 = dv(:,2).*dv(:,3) == 2*29;
q_ = qqs(~feb29) ;
sys_param.simulation.ev = ee(~feb29) ;
% remove negative value
q_(q_<0)= eps ;
sys_param.simulation.q = q_ ;

% structure with system paramenters
sys_param.simulation.s_in  = 458.6 ; % initial storage on 1/10/1995
sys_param.simulation.w     = [w(1:151); w(153:end)]  ; % remove 29feb
sys_param.simulation.EnvF  = 0  ;  % environmnetal flow (not considered)
sys_param.simulation.delta = 1; % daily time-step



%% set DDP optimization

% discretization of variables' domain (Hoa Binh case: ns=68, nu=17, nq=101)
grids.discr_s = [0:20:1000]' ; % taf
grids.discr_u = [[0:.01:7],[7:.2:9],[10:20:cfs_to_taf(115000)]]' ; % taf/day 
grids.discr_q = [[0:.1:50],[55:10:155]]' ; % taf/day
sys_param.algorithm = grids;
%[vv, VV] = construct_rel_matrices(grids); % compute daily minimum/maximum release matrixes
load ./data/minRel_table
load ./data/maxRel_table
sys_param.algorithm.min_rel = vv;
sys_param.algorithm.max_rel = VV;

% set algorithm parameters
sys_param.algorithm.name = 'ddp';
sys_param.algorithm.Hend = 0 ; % penalty set to 0
sys_param.algorithm.T = 365 ;    % the period is equal 1 year
sys_param.algorithm.gamma = 1; % set future discount factor


%% run DDP optimization
q_sim = sys_param.simulation.q ;
Hopt =  opt_ddp( q_sim ) ;
policy.H = Hopt ;
save -ascii ./output/BellmanDDP.txt Hopt

%% load Bellman function
policy.H   = load('./output/BellmanDDP.txt','-ascii') ;

%% run simulation of SDP-policies (2000-2100)
q_sim = sys_param.simulation.q ;
s_init = sys_param.simulation.s_in ;

[J, s,u,r, G] = simLake( q_sim, s_init, policy );
disp(J)
save ./output/workspaceDDP_82_fut.mat



