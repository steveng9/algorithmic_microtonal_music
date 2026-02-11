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


% function piano = piano_sound(freq, fs, dur)
%     t = 0:1/fs:dur;
% 
%     % Piano has very fast attack (almost instant)
%     attack_time = 0.003;  % 3ms - very quick
%     attack_samples = round(attack_time * fs);
%     attack_env = ones(size(t));
%     if attack_samples > 0
%         attack_env(1:attack_samples) = linspace(0, 1, attack_samples).^0.5;
%     end
% 
%     % Piano has complex harmonic structure with slight inharmonicity
%     % Lower harmonics are louder, higher ones decay faster
%     piano = sin(2*pi*freq*t) .* exp(-0.8*t) + ...              % Fundamental
%             0.7*sin(2*pi*freq*2.001*t) .* exp(-1.2*t) + ...    % 2nd harmonic (slightly sharp)
%             0.5*sin(2*pi*freq*3.002*t) .* exp(-1.5*t) + ...    % 3rd harmonic
%             0.3*sin(2*pi*freq*4.005*t) .* exp(-1.8*t) + ...    % 4th harmonic
%             0.2*sin(2*pi*freq*5.008*t) .* exp(-2.0*t) + ...    % 5th harmonic
%             0.15*sin(2*pi*freq*6.012*t) .* exp(-2.2*t) + ...   % 6th harmonic
%             0.1*sin(2*pi*freq*7.015*t) .* exp(-2.4*t) + ...    % 7th harmonic
%             0.08*sin(2*pi*freq*8.020*t) .* exp(-2.6*t);        % 8th harmonic
% 
%     % Add metallic "clang" at the beginning (hammer hitting string)
%     clang_dur = 0.01;  % 10ms
%     clang_samples = round(clang_dur * fs);
%     clang = randn(1, clang_samples) * 0.3 .* exp(-200*(0:clang_samples-1)/fs);
% 
%     % Add clang to the beginning
%     if length(piano) >= clang_samples
%         piano(1:clang_samples) = piano(1:clang_samples) + clang;
%     end
% 
%     % Apply attack envelope
%     piano = piano .* attack_env;
% 
%     % Fade out at the end to prevent clicking
%     fade_samples = min(round(0.02 * fs), length(piano));
%     fade_out = ones(size(piano));
%     fade_out(end-fade_samples+1:end) = linspace(1, 0, fade_samples);
%     piano = piano .* fade_out;
% 
%     % Normalize
%     piano = piano / max(abs(piano));
% end

% function piano = piano_sound(freq, fs, dur)
%     t = 0:1/fs:dur;
% 
%     % Very fast attack
%     attack_time = 0.002;
%     attack_samples = round(attack_time * fs);
%     attack_env = ones(size(t));
%     if attack_samples > 0
%         attack_env(1:attack_samples) = linspace(0, 1, attack_samples).^0.3;
%     end
% 
%     % More harmonics with inharmonicity (pianos aren't perfectly harmonic)
%     % The inharmonicity increases with harmonic number
%     inharmonicity = 0.0005;  % Typical for piano
% 
%     piano = zeros(size(t));
%     amplitudes = [1, 0.8, 0.6, 0.4, 0.3, 0.25, 0.2, 0.15, 0.12, 0.1];
%     decay_rates = [0.5, 0.8, 1.0, 1.2, 1.4, 1.6, 1.8, 2.0, 2.2, 2.4];
% 
%     for n = 1:length(amplitudes)
%         % Inharmonic frequency (slightly sharp for higher harmonics)
%         freq_n = freq * n * sqrt(1 + inharmonicity * n^2);
%         piano = piano + amplitudes(n) * sin(2*pi*freq_n*t) .* exp(-decay_rates(n)*t);
%     end
% 
%     % Percussive attack with noise
%     attack_noise_dur = 0.005;
%     attack_noise_samples = round(attack_noise_dur * fs);
%     attack_noise = randn(1, attack_noise_samples) * 0.4 .* exp(-300*(0:attack_noise_samples-1)/fs);
%     if length(piano) >= attack_noise_samples
%         piano(1:attack_noise_samples) = piano(1:attack_noise_samples) + attack_noise;
%     end
% 
%     piano = piano .* attack_env;
% 
%     % Fade out
%     fade_samples = min(round(0.02 * fs), length(piano));
%     fade_out = ones(size(piano));
%     fade_out(end-fade_samples+1:end) = linspace(1, 0, fade_samples);
%     piano = piano .* fade_out;
% 
%     piano = piano / max(abs(piano));
% end