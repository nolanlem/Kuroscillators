/****************************************************************************
*****************************************************************************

                            COUPLED OSCILLATORS

*****************************************************************************
*****************************************************************************/

import("stdfaust.lib");


process = coupledtrigs_env;


/*#***************************************************************************

                                TEST CASES

*****************************************************************************/


coupledtrigs = coupled_triggers(initial_phases, frequencies, coupling_factor) //: par(i, outputs(initial_phases), pm.djembe(50+10*i, 10+4*i, 50, 1))
    with {
  		N = 2;
  		initial_phases = par(i, N, 2*ma.PI*i/N); // spread equally around 0..2*pi
  		frequencies = par(i, N, 1*i);
        //coupling_factor = hslider("coupling", 0, 0, 0.2, 0.01);
   		coupling_factor = par(i, N, (hslider("coupling%i", 0.0, 0.0, 0.1, 0.0001):si.smooth(0.99)));
    };

coupledtrigs_env = coupled_triggers(initial_phases, frequencies, coupling_factor) //: par(i, outputs(initial_phases), pm.djembe(50+10*i, 10+4*i, 50, 1))
    with {
  		N = 2;
  		initial_phases = par(i, N, 2*ma.PI*i/N); // spread equally around 0..2*pi
  		//frequencies = par(i, N, 1 + 0.2*i);
        //coupling_factor = hslider("coupling", 0, 0, 0.2, 0.01);
  		// adjustable frequencies from 0.5 Hz -> 0.5+N*0.5Hz
  		frequencies = par(i, N, (hslider("freq%i", 0.5+0.5*i, 0.25, 30.0, 0.05):si.smooth(0.99)));


   		coupling_factor = par(i, N, (hslider("coupling%i", 0.0, 0.0, 0.01, 0.00001):si.smooth(0.99)));
};



// interleave used with 'audio' type
//interleave(N,M) = route(N*M, N*M, par(i, N*M, (i+1, (i%N)*M + int(i/N) + 1))); // time 0.1s◊

/****************************************************************************

                                IMPLEMENTATION

*****************************************************************************/

// coupled triggers are simply coupled phasors connected to a zero crossing function


coupled_triggers(inits, freqs, k) = coupled_phasors(inits, freqs, k) : par(i,N,zerocross) : env_sine
    with {
		zerocross(x) = x < x';
  		//noise(x) = os.oscsin(100);
		//zerocross = _ <: _,mem : <;
        N = outputs(inits);
        gate = checkbox("on") : si.smoo;
  		  env_sine = par(i, N, 0.8*gate*en.ar(0.001, hslider("rel%i", 0.05, 0.001, 0.5,0.001))*os.oscsin(hslider("oscfreq%i", 100+100*i, 100, 5000,1)));
    };

// coupled oscillators are simply coupled phasors connected to a sin function

 coupled_oscillators(inits, freqs, k) = coupled_phasors(inits, freqs, k) : par(i,N,sin)
     with {
         N=outputs(inits);
     };



// Coupled phasors : N adjustable phasors with N feedback adjustments
coupled_phasors(inits, freqs, k) = (si.bus(N), inits, freqs, k : ro.interleave(N,4) : par(i,N,adjustable_phasor)) ~ adjustments(N,k)
    with {
        N = outputs(inits);
    };


// adjustable phasor, with phase adjustment, initial phase and frequency
adjustable_phasor(adj,init,freq,k) = adj + (init-init') + freq*2*ma.PI/ma.SR : (+, 2*ma.PI : fmod) ~ _;


// Takes N phase signals and compute N adjustment signals
adjustments(N,K) = si.bus(N) <: (average(N) : split(N), split(N)), (si.bus(N), K)
                                      : ro.interleave(N,4)
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
