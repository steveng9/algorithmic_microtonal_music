fs = 44100;
dur = 0.45;
gap = 0.25;
root = microtonal.scales.note_to_freq('C4');

%% ---------------------------
% GET JI DATA
%% ---------------------------
ji = microtonal.scales.get_ji_scales();

%% ---------------------------
% BUILD SCALE FREQUENCIES
%% ---------------------------
maj12 = microtonal.scales.tet_scales(root, 12, ...
    microtonal.scales.get_mode(12,'major'), 1);

min12 = microtonal.scales.tet_scales(root, 12, ...
    microtonal.scales.get_mode(12,'minor'), 1);

chr12 = microtonal.scales.tet_scales(root, 12, ...
    microtonal.scales.get_mode(12,'chromatic'), 1);

majJI = microtonal.scales.ratio_scale(root, ji.major_5limit, 1);
minJI = microtonal.scales.ratio_scale(root, ji.minor_5limit, 1);

%% ---------------------------
% TIMING HELPER
%% ---------------------------
play_seq = @(freqs, name) ...
    microtonal.audio.build_audio_buffer( ...
        freqs, ...
        (0:length(freqs)-1) * (dur+gap), ...
        ones(size(freqs)) * dur, ...
        @vibraphone, fs);

%% ---------------------------
% BUILD AUDIO
%% ---------------------------
buf = [];

sections = {
    maj12, '12TET_major';
    majJI, 'JI_major';
    min12, '12TET_minor';
    minJI, 'JI_minor';
    chr12, '12TET_chromatic'
};

t_offset = 0;

for k = 1:size(sections,1)
    freqs = sections{k,1};

    times = t_offset + (0:length(freqs)-1)*(dur+gap);
    durs  = ones(size(freqs))*dur;

    b = microtonal.audio.build_audio_buffer(freqs, times, durs, @vibraphone, fs);
    buf = [buf; zeros(round(fs*gap),1); b];

    t_offset = length(buf)/fs;
end

%% ---------------------------
% TRIADS
%% ---------------------------
triad_dur = 2.2;

% 12-TET major triad
triad12 = root * [1 2^(4/12) 2^(7/12)];

% JI major triad
triadJI = root * [1 5/4 3/2];

for triad = {triad12, triadJI}
    freqs = triad{1};

    times = t_offset * ones(size(freqs));
    durs  = ones(size(freqs)) * triad_dur;

    b = microtonal.audio.build_audio_buffer(freqs, times, durs, @vibraphone, fs);
    buf = [buf; zeros(round(fs*gap),1); b];

    t_offset = length(buf)/fs;
end

%% ---------------------------
% PLAY
%% ---------------------------
microtonal.audio.play('tuning_comparison', buf, fs);
