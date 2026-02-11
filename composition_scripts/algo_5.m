
addpath('sounds');

note_durs = 6;
tet = 12;
scale = microtonal.tet_scales(microtonal.note_to_freq("A3"), tet, microtonal.get_mode(tet, 'major'), 3);
tone = @crystal_bowl_with_pop;

L = 20;
S = 8;
notes = [];
start_times = [];
for i = 1:S
    rhythm = exp((S-i)/S*2);
    disp(rhythm);
    s = 0:rhythm:L;
    start_times = [start_times, s];
    notes = [notes, repmat(scale(i), 1, length(s))];
end

durations = note_durs * ones(1, length(notes));


audio_buffer = microtonal.build_audio_buffer(notes, start_times, durations, tone);

microtonal.play("LCM_4", audio_buffer);














