function piano = piano_sound(freq, fs, dur)
    t = 0:1/fs:dur;
    
    % Instant attack (pianos are percussive)
    attack_time = 0.003;
    attack_samples = round(attack_time * fs);
    attack_env = ones(size(t));
    if attack_samples > 0
        attack_env(1:attack_samples) = linspace(0, 1, attack_samples);
    end
    
    % Piano sound - the key is the decay should be SLOW, not fast
    % Low notes sustain longer than high notes
    % Adjust decay based on frequency (lower = slower decay)
    base_decay = 0.3 + (440/freq) * 0.2;  % Lower notes decay slower
    
    % Build the sound with many harmonics
    % Each harmonic has slightly different decay
    piano = sin(2*pi*freq*t) .* exp(-base_decay*t) + ...
            0.6*sin(2*pi*freq*2*t) .* exp(-(base_decay+0.1)*t) + ...
            0.3*sin(2*pi*freq*3*t) .* exp(-(base_decay+0.2)*t) + ...
            0.2*sin(2*pi*freq*4*t) .* exp(-(base_decay+0.3)*t) + ...
            0.13*sin(2*pi*freq*5*t) .* exp(-(base_decay+0.4)*t) + ...
            0.1*sin(2*pi*freq*6*t) .* exp(-(base_decay+0.5)*t) + ...
            0.07*sin(2*pi*freq*7*t) .* exp(-(base_decay+0.6)*t) + ...
            0.04*sin(2*pi*freq*8*t) .* exp(-(base_decay+0.7)*t);
    
    % Very short hammer strike noise (the "thunk" of the key)
    strike_dur = 0.005;
    strike_samples = round(strike_dur * fs);
    strike = randn(1, strike_samples) * 0.2 .* exp(-500*(0:strike_samples-1)/fs);
    
    if length(piano) >= strike_samples
        piano(1:strike_samples) = piano(1:strike_samples) + strike;
    end
    
    piano = piano .* attack_env;
    
    % Fade out at end
    fade_samples = min(round(0.02 * fs), length(piano));
    fade_out = ones(size(piano));
    fade_out(end-fade_samples+1:end) = linspace(1, 0, fade_samples);
    piano = piano .* fade_out;
    
    piano = piano / max(abs(piano));
end
