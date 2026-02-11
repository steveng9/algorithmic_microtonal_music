
addpath('sounds');
fs = 44100;

% inorder_5tet = 1:4;
% inorder_7tet = 1:6;
% inorder_12tet = 1:11;
% inorder_19tet = 1:18;
% inorder_31tet = 1:30;
% inorder_37tet = 1:36;


dur = 4;

for i = [5, 7, 12, 19, 31, 37]
    % i = int16(i);
    scale = microtonal.tet_scales(microtonal.note_to_freq("c4"), i, 0:(i-1), 1);
    start_times = linspace(0, 8, i+1);
    % sep = .4;
    % start_times = 0:sep:i*sep;

    audio_buffer = microtonal.build_audio_buffer(scale, start_times, dur * ones(1, i+1), @tubular_bell);
    
        
    % Save and play 
    audiowrite('scales.wav', audio_buffer, fs);
    % sound(audio_buffer, fs);

    [y, Fs] = audioread('scales.wav');
    player = audioplayer(y, Fs);
    play(player);
    while isplaying(player)
        pause(0.1);
    end
    disp('Audio playback finished.');

    
end














