function [fitfun,xstart,insigma,inopts,varargin,cmaVersion,definput,defopts,flg_future_setting,nargin,input,opts,counteval,countevalNaN,irun ...
    flgresume, xmean,N,numberofvariables,lambda0,popsize,lambda,lambda_last,stopFitness,stopMaxFunEvals,stopMaxIter,stopFunEvals,stopIter, ... 
    stopTolFun,stopTolHistFun,stopOnStagnation,stopOnWarnings,flgreadsignals,flgWarnOnEqualFunctionValues,flgEvalParallel,stopOnEqualFunctionValues, ... 
    arrEqualFunvals, flgDiagonalOnly, flgActiveCMA,noiseHandling,noiseMinMaxEvals,noiseAlphaEvals,noiseCallback,flgdisplay,flgplotting,verbosemodulo, ... 
    flgscience,flgsaving,strsaving,flgsavingfinal, savemodulo,savetime,time,maxdx,mindx,lbounds,ubounds,stopTolX,stopTolUpX,sigma,pc,diagD,diagC,B,BD, ... 
    C,fitness,bnd,out,startseed,chiN,countiter,outiter,filenameprefix,filenames, lambda_hist,mu,weights,mueff,cc,cs,ccov1,ccovmu,ccov1_sep, ccovmu_sep, ... 
    damps,noiseReevals,noiseAlpha,noiseEpsilon,noiseTheta,noisecum,noiseCutOff,arx, arxvalid,tries,noiseS,noiseSS,noiseN,xold,zmean,fmean,ps,neg, ... 
    stopflag,noiseX,iterplotted,arfitness,Xnew_sorted,invsqrtC,stop] = cmaes_loadState(state)

fitfun = state.fitfun;
xstart = state.xstart;
insigma = state.insigma;
inopts = state.inopts;
varargin = state.varargin;
cmaVersion = state.cmaVersion;
definput = state.definput;
defopts = state.defopts;
flg_future_setting = state.flg_future_setting;
nargin = state.nargin;
input = state.input;
opts = state.opts;
irun = state.irun;

flgresume = state.flgresume;
N = state.N;
numberofvariables = state.numberofvariables;
lambda0 = state.lambda0;
lambda_last = state.lambda_last;
popsize = state.popsize;
lambda = state.lambda;
stopFitness = state.stopFitness;
stopMaxFunEvals = state.stopMaxFunEvals;
stopMaxIter = state.stopMaxIter;
stopFunEvals = state.stopFunEvals;
stopIter = state.stopIter;
stopTolFun = state.stopTolFun;
stopTolHistFun = state.stopTolHistFun;
stopOnStagnation = state.stopOnStagnation;
stopOnWarnings = state.stopOnWarnings;
flgreadsignals = state.flgreadsignals;
flgWarnOnEqualFunctionValues = state.flgWarnOnEqualFunctionValues;
flgEvalParallel = state.flgEvalParallel;
stopOnEqualFunctionValues = state.stopOnEqualFunctionValues;
arrEqualFunvals = state.arrEqualFunvals;
flgActiveCMA = state.flgActiveCMA;
noiseHandling = state.noiseHandling;
noiseMinMaxEvals = state.noiseMinMaxEvals;
noiseAlphaEvals = state.noiseAlphaEvals;
noiseCallback = state.noiseCallback;
flgdisplay = state.flgdisplay;
flgplotting = state.flgplotting;
verbosemodulo = state.verbosemodulo;
flgscience = state.flgscience;
flgsaving = state.flgsaving;
strsaving = state.strsaving;
flgsavingfinal = state.flgsavingfinal;
savetime = state.savetime;
maxdx = state.maxdx;
mindx = state.mindx;
lbounds = state.lbounds;
ubounds = state.ubounds;
stopTolX = state.stopTolX;
stopTolUpX = state.stopTolUpX;
B = state.B;
bnd = state.bnd;
startseed = state.startseed;
chiN = state.chiN;
filenameprefix = state.filenameprefix;
filenames = state.filenames;
lambda_hist = state.lambda_hist;
mu = state.mu;
weights = state.weights;
mueff = state.mueff;
cc = state.cc;
cs = state.cs;
ccov1 = state.ccov1;
ccovmu = state.ccovmu;
flgDiagonalOnly = state.flgDiagonalOnly;
ccov1_sep = state.ccov1_sep;
ccovmu_sep = state.ccovmu_sep;
damps = state.damps;
noiseReevals = state.noiseReevals;
noiseAlpha = state.noiseAlpha;
noiseEpsilon = state.noiseEpsilon;
noiseTheta = state.noiseTheta;
noisecum = state.noisecum;
noiseCutOff = state.noiseCutOff;
countiter = state.countiter;
fitness = state.fitness;
arx = state.arx;
arxvalid = state.arxvalid;
countevalNaN = state.countevalNaN;
counteval = state.counteval;
tries = state.tries;
noiseS = state.noiseS;
noiseSS = state.noiseSS;
noiseN = state.noiseN;
xold = state.xold;
xmean = state.xmean;
zmean = state.zmean;
fmean = state.fmean;
ps = state.ps;
pc = state.pc;
neg = state.neg;
diagC = state.diagC;
diagD = state.diagD;
C = state.C;
sigma = state.sigma;
stopflag = state.stopflag;
BD = state.BD;
noiseX = state.noiseX;
out = state.out;
time = state.time;
outiter = state.outiter;
iterplotted = state.iterplotted;
savemodulo = state.savemodulo;

arfitness = state.arfitness;
Xnew_sorted = state.Xnew_sorted;
invsqrtC = state.invsqrtC;

stop = state.stop;