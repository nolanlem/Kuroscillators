/****************************************************************************
*****************************************************************************

                            COUPLED OSCILLATORS

*****************************************************************************
*****************************************************************************/

import("stdfaust.lib");


process = gen_coupled_audio;


/****************************************************************************

                                TEST CASES

*****************************************************************************/

gen_coupled_audio = coupled_oscillators(initial_phases, frequencies, coupling_factor) :> /(N), /(N)
    with {
		N = 24;
        initial_phases = par(i, N, 2*ma.PI*i/N);    // in radians
        frequencies = par(i, N, (hslider("frequency%i", 100+33*i, 0.0, 5000, 0.0001):si.smoo));       // in Hz
        //coupling_factor = par(i, N, 0.001*i);
  		  coupling_factor = par(i, N, (hslider("coupling%i", 0.0, 0.0, 0.15, 0.0001):si.smoo));
      };

test_knmat_1 = coupled_oscillators(initial_phases, frequencies, coupling_factor)
    with {
		N = 3;
        initial_phases = par(i, N, 2*ma.PI*i/N);    // in radians
        frequencies = par(i, N, 100 + 77*i);       // in Hz
        //coupling_factor = par(i, N, 0.001*i);
  		coupling_factor = par(i, N, 0.001*i);
    };

test0 = coupled_oscillators(initial_phases, frequencies, coupling_factor)
    with {
        initial_phases = 0.2, 0.4, 1.3, 3;    // in radians
        frequencies = 300, 400, 500, 600;       // in Hz
        coupling_factor = 0.01, 0.005, 0.008, 0.02;
    };


test1 = coupled_oscillators(initial_phases, frequencies, coupling_factor)
    with {
        initial_phases = 0.2, 0.4, 1.3, 3;    // in radians
        frequencies = 300, 400, 500, 600;       // in Hz
        coupling_factor = hslider("coupling", 0, 0, 0.2, 0.01);
    };


test3 = coupled_oscillators(initial_phases, frequencies, coupling_factor)
    with {
        initial_phases = 0.2, 0.4, 1.3, 3;    // in radians
        frequencies = 300, 400, 500, 600;       // in Hz
        coupling_factor = hslider("coupling", 0, 0, 0.2, 0.01)*adjustable_phasor(0,0,0.1);
    };



test2 = coupled_triggers(initial_phases, frequencies, coupling_factor) //: par(i, outputs(initial_phases), pm.djembe(50+10*i, 10+4*i, 50, 1))
    with {
        initial_phases = 0.2, 0.4, 1.3, 3;    // in radians
        frequencies = 0.300, 0.400, 0.500, 0.600;       // in Hz
        coupling_factor = hslider("coupling", 0, 0, 0.2, 0.01);
    };

//    /(N)  ==> _,N : /

test4 = coupled_oscillators(initial_phases, frequencies, coupling_factor) :> /(N), /(N)
    with {
		N = 10;
        initial_phases = par(i, N, 2*ma.PI*i/N);    // in radians
        frequencies = par(i, N, 100 + 77*i);       // in Hz
        coupling_factor = hslider("coupling", 0, 0, 0.2, 0.01)*adjustable_phasor(0,0,0.1);
    };

test5 = coupled_oscillators(initial_phases, frequencies, coupling_factor) :> /(N), /(N)
    with {
		N = 10;
        initial_phases = par(i, N, 2*ma.PI*i/N);    // in radians
        frequencies = par(i, N, 100 + 77*i);       // in Hz
        coupling_factor = hslider("coupling", 0, 0, 0.2, 0.01)*os.lf_triangle(0.05);
    };


interleave(N,M) = route(N*M, N*M, par(i, N*M, (i+1, (i%N)*M + int(i/N) + 1))); // time 0.1s◊

/****************************************************************************

                                IMPLEMENTATION

*****************************************************************************/

// coupled triggers are simply coupled phasors connected to a zero crossing function

coupled_triggers(inits, freqs, k) = coupled_phasors(inits, freqs, k) : par(i,N,zerocross)
    with {
		zerocross(x) = x < x';
		//zerocross = _ <: _,mem : <;
        N=outputs(inits);
    };

// coupled oscillators are simply coupled phasors connected to a sin function

coupled_oscillators(inits, freqs, k) = coupled_phasors(inits, freqs, k) : par(i,N,sin)
    with {
        N=outputs(inits);
    };


// Coupled phasors : N adjustable phasors with N feedback adjustments

coupled_phasors(inits, freqs, k) = (si.bus(N), inits, freqs, k : interleave(N,4) : par(i,N,adjustable_phasor)) ~ adjustments(N,k)
    with {
        N = outputs(inits);
    };


//adjustable_phasor_kmat(adj,init,freq) = adj + (init-init') + freq*2*ma.PI/ma.SR : (+, 2*ma.PI : fmod) ~ _;


// adjustable phasor, with phase adjustement, initial phase and frequency
adjustable_phasor(adj,init,freq,k) = adj + (init-init') + freq*2*ma.PI/ma.SR : (+, 2*ma.PI : fmod) ~ _;


// Takes N phase signals and compute N adjutement signals
adjustments(N,K) = si.bus(N) <: (average(N) : split(N), split(N)), (si.bus(N), K)
                                      : interleave(N,4)
                                      : par(i, N, adjustement)

    with {
        // compute the average of N phase signals
        average(N) = par(i, N, (_<:cos,sin)) :> c2p : /(N),_;
        // split a signal into N copies
        split(N) = _ <: si.bus(N);
        // compute the phase adjustement factor
        adjustement(R,psi,phi,K) = K*R*sin(psi-phi);
        // cartesian to polar
        c2p(x,y) = sqrt(x^2+y^2), atan2(y,x);
    };

// Takes N phase signals and compute N adjutement signals
//adjustments(N,K) = si.bus(N) <: (average(N) : split(N), split(N)), (si.bus(N), si.bus(N))
//                                      : ro.interleave(N,4)
//                                      : par(i,N, adjustement)

//    with {
        // compute the average of N phase signals
//        average(N) = par(i, N, (_<:cos,sin)) :> c2p : /(N),_;
        // split a signal into N copies
//        split(N) = _ <: si.bus(N);
        // compute the phase adjustement factor
//        adjustement(R,psi,phi,K) = K*R*sin(psi-phi);
        // cartesian to polar
//        c2p(x,y) = sqrt(x^2+y^2), atan2(y,x);
//    };
